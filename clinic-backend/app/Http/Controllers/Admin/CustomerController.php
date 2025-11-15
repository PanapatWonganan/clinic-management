<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\CustomerAddress;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;

class CustomerController extends Controller
{
    /**
     * Display a listing of customers.
     */
    public function index(Request $request)
    {
        // If API request, return JSON
        if ($request->expectsJson() || $request->is('*/api/*')) {
            $customers = User::orderBy('created_at', 'desc')->get();
            
            // Add membership info to each customer
            $customers->each(function ($customer) {
                $customer->membership_info = $customer->getMembershipInfo();
                $customer->membership_status = $customer->getMembershipStatus();
            });
            
            return response()->json([
                'success' => true,
                'data' => $customers
            ]);
        }

        // For web requests, return view
        // Eager load addresses to avoid N+1 query problem
        $customers = User::with('addresses')->orderBy('created_at', 'desc')->paginate(15);
        
        // Add membership info to each customer
        $customers->getCollection()->each(function ($customer) {
            $customer->membership_info = $customer->getMembershipInfo();
            $customer->membership_status = $customer->getMembershipStatus();
        });

        $stats = [
            'total_customers' => User::count(),
            'new_customers_this_month' => User::whereMonth('created_at', now()->month)->count(),
            'membership_breakdown' => User::selectRaw('membership_type, COUNT(*) as count')
                ->groupBy('membership_type')
                ->get()
        ];
        
        return view('admin.customers.index', compact('customers', 'stats'));
    }

    /**
     * Store a newly created customer.
     */
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
            'password' => 'required|string|min:8',
            'phone' => 'nullable|string|max:20',
            'address' => 'nullable|string|max:500',
            'district' => 'nullable|string|max:100',
            'province' => 'nullable|string|max:100',
            'postal_code' => 'nullable|string|max:10',
            // New Thai address fields
            'province_id' => 'nullable|integer',
            'district_id' => 'nullable|integer', 
            'sub_district_id' => 'nullable|integer',
            // Membership validation
            'membership_type' => 'nullable|in:exMember,exDoctor,exVip,exSupervip',
            'membership_end_date' => 'nullable|date|after:today',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'ข้อมูลไม่ถูกต้อง',
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            // Set default membership to exMember if not provided
            $membershipType = $request->membership_type ?? User::MEMBERSHIP_EXMEMBER;
            $membershipTypes = User::getMembershipTypes();
            $membershipInfo = $membershipTypes[$membershipType];

            $customer = User::create([
                'name' => $request->name,
                'email' => $request->email,
                'password' => Hash::make($request->password),
                'phone' => $request->phone,
                'address' => $request->address,
                'district' => $request->district,
                'province' => $request->province,
                'postal_code' => $request->postal_code,
                // New Thai address fields
                'province_id' => $request->province_id,
                'district_id' => $request->district_id,
                'sub_district_id' => $request->sub_district_id,
                'email_verified_at' => now(),
                // Membership data
                'membership_type' => $membershipType,
                'membership_start_date' => now(),
                'membership_end_date' => $request->membership_end_date,
                'membership_benefits' => $membershipInfo['benefits'],
                'membership_discount_rate' => $membershipInfo['discount_rate'],
                'membership_point_multiplier' => $membershipInfo['point_multiplier'],
            ]);

            // Load membership info for response
            $customer->refresh(); // Refresh the model
            $customer->membership_info = $customer->getMembershipInfo();
            $customer->membership_status = $customer->getMembershipStatus();

            return response()->json([
                'success' => true,
                'message' => 'เพิ่มลูกค้าสำเร็จ',
                'data' => $customer
            ], 201);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'เกิดข้อผิดพลาดในการเพิ่มลูกค้า: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Display the specified customer.
     */
    public function show(string $id)
    {
        try {
            $customer = User::findOrFail($id);
            
            // Add membership info
            $customer->membership_info = $customer->getMembershipInfo();
            $customer->membership_status = $customer->getMembershipStatus();
            
            return response()->json([
                'success' => true,
                'data' => $customer
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'ไม่พบลูกค้า'
            ], 404);
        }
    }

    /**
     * Update the specified customer.
     */
    public function update(Request $request, string $id)
    {
        try {
            $customer = User::findOrFail($id);

            $validator = Validator::make($request->all(), [
                'name' => 'required|string|max:255',
                'email' => 'required|string|email|max:255|unique:users,email,' . $id,
                'password' => 'nullable|string|min:8',
                'phone' => 'nullable|string|max:20',
                'address' => 'nullable|string|max:500',
                'district' => 'nullable|string|max:100',
                'province' => 'nullable|string|max:100',
                'postal_code' => 'nullable|string|max:10',
                // Membership validation
                'membership_type' => 'nullable|in:exMember,exDoctor,exVip,exSupervip',
                'membership_end_date' => 'nullable|date|after:today',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'ข้อมูลไม่ถูกต้อง',
                    'errors' => $validator->errors()
                ], 422);
            }

            $updateData = [
                'name' => $request->name,
                'email' => $request->email,
                'phone' => $request->phone,
                'address' => $request->address,
                'district' => $request->district,
                'province' => $request->province,
                'postal_code' => $request->postal_code,
                // New Thai address fields
                'province_id' => $request->province_id,
                'district_id' => $request->district_id,
                'sub_district_id' => $request->sub_district_id,
            ];

            if ($request->filled('password')) {
                $updateData['password'] = Hash::make($request->password);
            }

            // Handle membership update
            if ($request->filled('membership_type')) {
                $membershipType = $request->membership_type;
                $membershipTypes = User::getMembershipTypes();
                $membershipInfo = $membershipTypes[$membershipType];

                // If membership type is changing, update start date
                if ($customer->membership_type !== $membershipType) {
                    $updateData['membership_start_date'] = now();
                }

                $updateData['membership_type'] = $membershipType;
                $updateData['membership_benefits'] = $membershipInfo['benefits'];
                $updateData['membership_discount_rate'] = $membershipInfo['discount_rate'];
                $updateData['membership_point_multiplier'] = $membershipInfo['point_multiplier'];
            }

            if ($request->filled('membership_end_date')) {
                $updateData['membership_end_date'] = $request->membership_end_date;
            }

            $customer->update($updateData);

            // Load membership info for response
            $freshCustomer = $customer->fresh();
            $freshCustomer->membership_info = $freshCustomer->getMembershipInfo();
            $freshCustomer->membership_status = $freshCustomer->getMembershipStatus();

            return response()->json([
                'success' => true,
                'message' => 'อัพเดตลูกค้าสำเร็จ',
                'data' => $freshCustomer
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'เกิดข้อผิดพลาดในการอัพเดตลูกค้า: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Remove the specified customer.
     */
    public function destroy(string $id)
    {
        try {
            $customer = User::findOrFail($id);
            $customer->delete();

            return response()->json([
                'success' => true,
                'message' => 'ลบลูกค้าสำเร็จ'
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'เกิดข้อผิดพลาดในการลบลูกค้า: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get customer addresses
     */
    public function getAddresses($id)
    {
        try {
            $customer = User::findOrFail($id);
            $addresses = $customer->addresses()->orderBy('is_default', 'desc')->orderBy('created_at', 'desc')->get();
            
            return response()->json([
                'success' => true,
                'customer_name' => $customer->name,
                'addresses' => $addresses
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'เกิดข้อผิดพลาดในการดึงข้อมูลที่อยู่: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get customer statistics
     */
    public function stats()
    {
        try {
            $totalCustomers = User::count();
            $newCustomersThisMonth = User::whereMonth('created_at', now()->month)
                ->whereYear('created_at', now()->year)
                ->count();
            $newCustomersToday = User::whereDate('created_at', today())->count();

            return response()->json([
                'success' => true,
                'data' => [
                    'total_customers' => $totalCustomers,
                    'new_customers_this_month' => $newCustomersThisMonth,
                    'new_customers_today' => $newCustomersToday
                ]
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'เกิดข้อผิดพลาดในการดึงสถิติลูกค้า: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get available membership types
     */
    public function getMembershipTypes()
    {
        try {
            $membershipTypes = User::getMembershipTypes();
            
            return response()->json([
                'success' => true,
                'data' => $membershipTypes
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'เกิดข้อผิดพลาดในการดึงข้อมูล membership types: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Update customer membership
     */
    public function updateMembership(Request $request, string $id)
    {
        try {
            $customer = User::findOrFail($id);

            $validator = Validator::make($request->all(), [
                'membership_type' => 'required|in:exMember,exDoctor,exVip,exSupervip',
                'membership_end_date' => 'nullable|date|after:today',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'ข้อมูลไม่ถูกต้อง',
                    'errors' => $validator->errors()
                ], 422);
            }

            $membershipType = $request->membership_type;
            $membershipTypes = User::getMembershipTypes();
            $membershipInfo = $membershipTypes[$membershipType];

            $updateData = [
                'membership_type' => $membershipType,
                'membership_start_date' => now(),
                'membership_end_date' => $request->membership_end_date,
                'membership_benefits' => $membershipInfo['benefits'],
                'membership_discount_rate' => $membershipInfo['discount_rate'],
                'membership_point_multiplier' => $membershipInfo['point_multiplier'],
            ];

            $customer->update($updateData);

            // Load membership info for response
            $freshCustomer = $customer->fresh();
            $freshCustomer->membership_info = $freshCustomer->getMembershipInfo();
            $freshCustomer->membership_status = $freshCustomer->getMembershipStatus();

            return response()->json([
                'success' => true,
                'message' => 'อัพเดต membership สำเร็จ',
                'data' => $freshCustomer
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'เกิดข้อผิดพลาดในการอัพเดต membership: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get membership statistics
     */
    public function getMembershipStats()
    {
        try {
            $membershipStats = [
                'total_by_type' => [],
                'active_memberships' => 0,
                'expired_memberships' => 0,
                'revenue_potential' => 0
            ];

            $membershipTypes = User::getMembershipTypes();
            
            foreach ($membershipTypes as $type => $info) {
                $count = User::where('membership_type', $type)->count();
                $membershipStats['total_by_type'][$type] = [
                    'count' => $count,
                    'name' => $info['name'],
                    'color' => $info['color']
                ];
            }

            // Count active vs expired memberships
            $membershipStats['active_memberships'] = User::whereNotNull('membership_start_date')
                ->where(function($query) {
                    $query->whereNull('membership_end_date')
                          ->orWhere('membership_end_date', '>', now());
                })->count();

            $membershipStats['expired_memberships'] = User::whereNotNull('membership_end_date')
                ->where('membership_end_date', '<=', now())->count();

            return response()->json([
                'success' => true,
                'data' => $membershipStats
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'เกิดข้อผิดพลาดในการดึงสถิติ membership: ' . $e->getMessage()
            ], 500);
        }
    }
}
