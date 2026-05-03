<?php

namespace App\Http\Controllers;

use App\Models\Product;
use Illuminate\Http\Request;
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
            if ($user) {
                $override = config('membership.main_product_price_overrides.'.$user->membership_type);
                if ($override !== null) {
                    $products = $products->map(function ($product) use ($override) {
                        $product->price = (float) $override;

                        return $product;
                    });
                }
            }
        }

        $products = $this->rewriteStoredImageUrls($products);

        return response()->json([
            'success' => true,
            'data' => $products,
            'total' => $products->count(),
        ]);
    }

    /**
     * Rewrite legacy `http://10.0.2.2:8000/storage/...` URLs (left over from
     * Android emulator dev builds) to the current host's CORS-friendly
     * `/api/storage/...` path. The hard-coded host used to live inline in
     * three controller methods; collecting it here keeps the rule in one
     * place and lets the configured legacy host be overridden via env if
     * we ever pivot to a new dev URL.
     */
    private function rewriteStoredImageUrls($products)
    {
        $baseUrl = request()->getSchemeAndHttpHost();
        $legacyHost = config('app.legacy_image_host', 'http://10.0.2.2:8000');

        return $products->map(function ($product) use ($baseUrl, $legacyHost) {
            if ($product->image_url && str_starts_with($product->image_url, $legacyHost)) {
                $product->image_url = str_replace(
                    $legacyHost.'/storage/',
                    $baseUrl.'/api/storage/',
                    $product->image_url
                );
            }

            return $product;
        });
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
        if ($user) {
            $override = config('membership.main_product_price_overrides.'.$user->membership_type);
            if ($override !== null) {
                $products = $products->map(function ($product) use ($override) {
                    $product->price = (float) $override;

                    return $product;
                });
            }
        }

        $products = $this->rewriteStoredImageUrls($products);

        return response()->json([
            'success' => true,
            'data' => $products,
            'total' => $products->count(),
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

        $products = $this->rewriteStoredImageUrls($products);

        return response()->json([
            'success' => true,
            'data' => $products,
            'total' => $products->count(),
        ]);
    }

    /**
     * Get single product
     */
    public function show($id)
    {
        $product = Product::where('is_active', true)->find($id);

        if (! $product) {
            return response()->json([
                'success' => false,
                'message' => 'Product not found',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => $product,
        ]);
    }

    /**
     * Update product stock
     */
    public function updateStock(Request $request, $id)
    {
        $validator = \Illuminate\Support\Facades\Validator::make($request->all(), [
            'quantity' => 'required|integer|min:0',
        ]);
        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors(),
            ], 422);
        }

        $product = Product::find($id);

        if (! $product) {
            return response()->json([
                'success' => false,
                'message' => 'Product not found',
            ], 404);
        }

        $product->update(['stock' => $request->quantity]);

        return response()->json([
            'success' => true,
            'message' => 'Stock updated successfully',
            'data' => $product,
        ]);
    }

    /**
     * Store a new product
     */
    public function store(Request $request)
    {
        $validator = \Illuminate\Support\Facades\Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'description' => 'nullable|string',
            'price' => 'required|numeric|min:0',
            'stock' => 'required|integer|min:0',
            'category' => 'nullable|in:main,reward',
            'points' => 'nullable|integer|min:0',
            'image' => 'nullable|image|mimes:jpeg,png,jpg,gif|max:2048',
        ]);
        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors(),
            ], 422);
        }

        $data = $request->except('image');

        // Handle image upload — use Laravel's hashName() for collision-resistant
        // and path-traversal-safe filenames; the original client name is
        // attacker-controlled and could embed slashes.
        if ($request->hasFile('image')) {
            $image = $request->file('image');
            $path = $image->storeAs('products', $image->hashName(), 'public');
            $data['image_url'] = Storage::url($path);
        }

        $product = Product::create($data);

        return response()->json([
            'success' => true,
            'message' => 'Product created successfully',
            'data' => $product,
        ], 201);
    }

    /**
     * Update a product
     */
    public function update(Request $request, $id)
    {
        $product = Product::find($id);

        if (! $product) {
            return response()->json([
                'success' => false,
                'message' => 'Product not found',
            ], 404);
        }

        $validator = \Illuminate\Support\Facades\Validator::make($request->all(), [
            'name' => 'nullable|string|max:255',
            'description' => 'nullable|string',
            'price' => 'nullable|numeric|min:0',
            'stock' => 'nullable|integer|min:0',
            'category' => 'nullable|in:main,reward',
            'points' => 'nullable|integer|min:0',
            'image' => 'nullable|image|mimes:jpeg,png,jpg,gif|max:2048',
        ]);
        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors(),
            ], 422);
        }

        $data = $request->except('image');

        // Handle image upload — see store() for why hashName() is used.
        if ($request->hasFile('image')) {
            if ($product->image_url && ! str_starts_with($product->image_url, 'http')) {
                $oldPath = str_replace('/storage/', '', $product->image_url);
                Storage::disk('public')->delete($oldPath);
            }

            $image = $request->file('image');
            $path = $image->storeAs('products', $image->hashName(), 'public');
            $data['image_url'] = Storage::url($path);
        }

        $product->update($data);

        return response()->json([
            'success' => true,
            'message' => 'Product updated successfully',
            'data' => $product,
        ]);
    }

    /**
     * Delete a product
     */
    public function destroy($id)
    {
        $product = Product::find($id);

        if (! $product) {
            return response()->json([
                'success' => false,
                'message' => 'Product not found',
            ], 404);
        }

        // Delete image if exists
        if ($product->image_url && ! str_starts_with($product->image_url, 'http')) {
            $path = str_replace('/storage/', '', $product->image_url);
            Storage::disk('public')->delete($path);
        }

        $product->delete();

        return response()->json([
            'success' => true,
            'message' => 'Product deleted successfully',
        ]);
    }
}
