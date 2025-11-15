<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Product;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Storage;

class ProductController extends Controller
{
    /**
     * Display a listing of products.
     */
    public function index(Request $request)
    {
        // If API request, return JSON
        if ($request->expectsJson() || $request->is('*/api/*')) {
            $products = Product::orderBy('created_at', 'desc')->get();
            return response()->json([
                'success' => true,
                'data' => $products
            ]);
        }

        // For web requests, return view
        $products = Product::orderBy('created_at', 'desc')->paginate(15);

        $stats = [
            'total_products' => Product::count(),
            'active_products' => Product::where('is_active', true)->count(),
            'low_stock_products' => Product::where('stock', '<=', 10)->count(),
            'out_of_stock_products' => Product::where('stock', 0)->count(),
            'category_breakdown' => Product::selectRaw('category, COUNT(*) as count')
                ->groupBy('category')
                ->get(),
            'total_value' => Product::sum(\DB::raw('price * stock'))
        ];
        
        return view('admin.products.index', compact('products', 'stats'));
    }

    /**
     * Store a newly created product.
     */
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'price' => 'required|numeric|min:0',
            'stock' => 'required|integer|min:0',
            'category' => 'required|in:main,rewards',
            'description' => 'nullable|string|max:1000',
            'image' => 'nullable|image|mimes:jpeg,png,jpg,gif|max:2048',
            'is_active' => 'boolean',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'ข้อมูลไม่ถูกต้อง',
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            $data = [
                'name' => $request->name,
                'price' => $request->price,
                'stock' => $request->stock,
                'category' => $request->category,
                'description' => $request->description,
                'is_active' => $request->boolean('is_active', true),
                'points' => 0, // Default points value
            ];

            // Handle image upload
            if ($request->hasFile('image')) {
                $image = $request->file('image');
                $imageName = time() . '_' . $image->getClientOriginalName();
                $path = $image->storeAs('products', $imageName, 'public');
                $data['image_url'] = Storage::url($path);
            }

            $product = Product::create($data);

            return response()->json([
                'success' => true,
                'message' => 'เพิ่มสินค้าสำเร็จ',
                'data' => $product
            ], 201);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'เกิดข้อผิดพลาดในการเพิ่มสินค้า: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Display the specified product.
     */
    public function show(string $id)
    {
        try {
            $product = Product::findOrFail($id);
            return response()->json([
                'success' => true,
                'data' => $product
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'ไม่พบสินค้า'
            ], 404);
        }
    }

    /**
     * Update the specified product.
     */
    public function update(Request $request, string $id)
    {
        try {
            $product = Product::findOrFail($id);

            $validator = Validator::make($request->all(), [
                'name' => 'required|string|max:255',
                'price' => 'required|numeric|min:0',
                'stock' => 'required|integer|min:0',
                'category' => 'required|in:main,rewards',
                'description' => 'nullable|string|max:1000',
                'image' => 'nullable|image|mimes:jpeg,png,jpg,gif|max:2048',
                'is_active' => 'boolean',
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
                'price' => $request->price,
                'stock' => $request->stock,
                'category' => $request->category,
                'description' => $request->description,
                'is_active' => $request->boolean('is_active', true),
            ];

            // Handle image upload
            if ($request->hasFile('image')) {
                // Delete old image if exists
                if ($product->image_url && !str_starts_with($product->image_url, 'http')) {
                    $oldPath = str_replace('/storage/', '', $product->image_url);
                    Storage::disk('public')->delete($oldPath);
                }

                $image = $request->file('image');
                $imageName = time() . '_' . $image->getClientOriginalName();
                $path = $image->storeAs('products', $imageName, 'public');
                $updateData['image_url'] = Storage::url($path);
            }

            $product->update($updateData);

            return response()->json([
                'success' => true,
                'message' => 'อัพเดตสินค้าสำเร็จ',
                'data' => $product->fresh()
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'เกิดข้อผิดพลาดในการอัพเดตสินค้า: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Remove the specified product.
     */
    public function destroy(string $id)
    {
        try {
            $product = Product::findOrFail($id);

            // Check if product has associated orders
            if ($product->orderItems()->count() > 0) {
                return response()->json([
                    'success' => false,
                    'message' => 'ไม่สามารถลบสินค้าที่มีรายการสั่งซื้อแล้ว'
                ], 422);
            }

            // Delete image if exists
            if ($product->image_url && !str_starts_with($product->image_url, 'http')) {
                $path = str_replace('/storage/', '', $product->image_url);
                Storage::disk('public')->delete($path);
            }

            $product->delete();

            return response()->json([
                'success' => true,
                'message' => 'ลบสินค้าสำเร็จ'
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'เกิดข้อผิดพลาดในการลบสินค้า: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get product statistics
     */
    public function stats()
    {
        try {
            $totalProducts = Product::count();
            $activeProducts = Product::where('is_active', true)->count();
            $inactiveProducts = Product::where('is_active', false)->count();
            $lowStockProducts = Product::where('stock', '<=', 10)->count();
            $outOfStockProducts = Product::where('stock', 0)->count();

            return response()->json([
                'success' => true,
                'data' => [
                    'total_products' => $totalProducts,
                    'active_products' => $activeProducts,
                    'inactive_products' => $inactiveProducts,
                    'low_stock_products' => $lowStockProducts,
                    'out_of_stock_products' => $outOfStockProducts
                ]
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'เกิดข้อผิดพลาดในการดึงสถิติสินค้า: ' . $e->getMessage()
            ], 500);
        }
    }
}