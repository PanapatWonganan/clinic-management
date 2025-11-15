<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Product;
use Illuminate\Support\Facades\Storage;

class ProductController extends Controller
{
    /**
     * Get all products
     */
    public function index()
    {
        $query = Product::where('is_active', true);

        // Filter by category if provided
        if (request()->has('category')) {
            $query->where('category', request('category'));
        }

        $products = $query->get();

        // Apply membership-based pricing for main products if user is authenticated
        if (request('category') === 'main') {
            $user = auth('sanctum')->user();
            if ($user && $user->membership_type === 'exDoctor') {
                // Apply special pricing for exDoctor membership
                $products = $products->map(function ($product) {
                    $product->price = 850.00; // Special price for exDoctor
                    return $product;
                });
            }
        }

        // Transform image URLs to use current host with /api/storage path for CORS support
        $baseUrl = request()->getSchemeAndHttpHost();
        $products = $products->map(function ($product) use ($baseUrl) {
            if ($product->image_url && str_starts_with($product->image_url, 'http://10.0.2.2:8000')) {
                // Replace with /api/storage path which has CORS headers
                $product->image_url = str_replace('http://10.0.2.2:8000/storage/', $baseUrl . '/api/storage/', $product->image_url);
            }
            return $product;
        });

        return response()->json([
            'success' => true,
            'data' => $products,
            'total' => $products->count()
        ]);
    }
    
    /**
     * Get main products (for home screen)
     */
    public function getMainProducts()
    {
        $products = Product::where('category', 'main')
                          ->where('is_active', true)
                          ->get();

        // Apply membership-based pricing if user is authenticated
        $user = auth('sanctum')->user();
        if ($user && $user->membership_type === 'exDoctor') {
            // Apply special pricing for exDoctor membership
            $products = $products->map(function ($product) {
                $product->price = 850.00; // Special price for exDoctor
                return $product;
            });
        }

        // Transform image URLs to use current host with /api/storage path for CORS support
        $baseUrl = request()->getSchemeAndHttpHost();
        $products = $products->map(function ($product) use ($baseUrl) {
            if ($product->image_url && str_starts_with($product->image_url, 'http://10.0.2.2:8000')) {
                // Replace with /api/storage path which has CORS headers
                $product->image_url = str_replace('http://10.0.2.2:8000/storage/', $baseUrl . '/api/storage/', $product->image_url);
            }
            return $product;
        });

        return response()->json([
            'success' => true,
            'data' => $products,
            'total' => $products->count()
        ]);
    }
    
    /**
     * Get reward products
     */
    public function getRewardProducts()
    {
        $products = Product::where('category', 'reward')
                          ->where('is_active', true)
                          ->get();

        // Transform image URLs to use current host with /api/storage path for CORS support
        $baseUrl = request()->getSchemeAndHttpHost();
        $products = $products->map(function ($product) use ($baseUrl) {
            if ($product->image_url && str_starts_with($product->image_url, 'http://10.0.2.2:8000')) {
                // Replace with /api/storage path which has CORS headers
                $product->image_url = str_replace('http://10.0.2.2:8000/storage/', $baseUrl . '/api/storage/', $product->image_url);
            }
            return $product;
        });

        return response()->json([
            'success' => true,
            'data' => $products,
            'total' => $products->count()
        ]);
    }
    
    /**
     * Get single product
     */
    public function show($id)
    {
        $product = Product::where('is_active', true)->find($id);
        
        if (!$product) {
            return response()->json([
                'success' => false,
                'message' => 'Product not found'
            ], 404);
        }
        
        return response()->json([
            'success' => true,
            'data' => $product
        ]);
    }
    
    /**
     * Update product stock
     */
    public function updateStock(Request $request, $id)
    {
        $request->validate([
            'quantity' => 'required|integer|min:0'
        ]);

        $product = Product::find($id);

        if (!$product) {
            return response()->json([
                'success' => false,
                'message' => 'Product not found'
            ], 404);
        }

        $product->update(['stock' => $request->quantity]);

        return response()->json([
            'success' => true,
            'message' => 'Stock updated successfully',
            'data' => $product
        ]);
    }

    /**
     * Store a new product
     */
    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'description' => 'nullable|string',
            'price' => 'required|numeric|min:0',
            'stock' => 'required|integer|min:0',
            'category' => 'nullable|in:main,reward',
            'points' => 'nullable|integer|min:0',
            'image' => 'nullable|image|mimes:jpeg,png,jpg,gif|max:2048'
        ]);

        $data = $request->except('image');

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
            'message' => 'Product created successfully',
            'data' => $product
        ], 201);
    }

    /**
     * Update a product
     */
    public function update(Request $request, $id)
    {
        $product = Product::find($id);

        if (!$product) {
            return response()->json([
                'success' => false,
                'message' => 'Product not found'
            ], 404);
        }

        $request->validate([
            'name' => 'nullable|string|max:255',
            'description' => 'nullable|string',
            'price' => 'nullable|numeric|min:0',
            'stock' => 'nullable|integer|min:0',
            'category' => 'nullable|in:main,reward',
            'points' => 'nullable|integer|min:0',
            'image' => 'nullable|image|mimes:jpeg,png,jpg,gif|max:2048'
        ]);

        $data = $request->except('image');

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
            $data['image_url'] = Storage::url($path);
        }

        $product->update($data);

        return response()->json([
            'success' => true,
            'message' => 'Product updated successfully',
            'data' => $product
        ]);
    }

    /**
     * Delete a product
     */
    public function destroy($id)
    {
        $product = Product::find($id);

        if (!$product) {
            return response()->json([
                'success' => false,
                'message' => 'Product not found'
            ], 404);
        }

        // Delete image if exists
        if ($product->image_url && !str_starts_with($product->image_url, 'http')) {
            $path = str_replace('/storage/', '', $product->image_url);
            Storage::disk('public')->delete($path);
        }

        $product->delete();

        return response()->json([
            'success' => true,
            'message' => 'Product deleted successfully'
        ]);
    }
}