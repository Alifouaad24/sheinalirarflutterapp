/// Everything that depends on SHEIN's markup lives in this file.
///
/// SHEIN changes its front-end regularly. When something stops working,
/// inspect the page (see README → "Updating SHEIN selectors") and update the
/// lists below — no other file needs to change. Every list is tried in order
/// and the first match wins, so put the most specific selectors first.
abstract final class SheinSelectors {
  // ---------------------------------------------------------------------------
  // Product page detection
  // ---------------------------------------------------------------------------

  /// Product URLs look like `.../Some-Dress-p-12345678.html` (sometimes with a
  /// `-cat-1234` suffix). Group 1 is the product id.
  static final RegExp productUrlPattern = RegExp(
    r'-p-(\d+)(?:-cat-\d+)?\.html',
    caseSensitive: false,
  );

  // ---------------------------------------------------------------------------
  // Product data (DOM fallbacks — JSON-LD and og: meta tags are tried first)
  // ---------------------------------------------------------------------------

  static const List<String> title = [
    '.product-intro__head-name',
    '.goods-name',
    '.product-intro__head-mainTitle',
    '[class*="goods-detail"] h1',
    'h1',
  ];

  static const List<String> price = [
    '.product-intro__head-mainprice .from',
    '.product-intro__head-price .from',
    '.product-intro__head-mainprice',
    '.goods-price__from',
    '.product-price__main',
    '[class*="sale-price"]',
    '[class*="main-price"]',
  ];

  static const List<String> mainImage = [
    '.product-intro__main-item img',
    '.product-intro__galleryWrap img',
    '.crop-image-container img',
    '.goods-detail-top img',
    '[class*="main-picture"] img',
  ];

  /// Product gallery images (fallback when the gallery container can't be
  /// found from the main photo).
  static const List<String> galleryImages = [
    '.product-intro__main-item img',
    '.product-intro__thumbs-item img',
    '.goods-detail-top img',
    '[class*="main-picture"] img',
  ];

  /// Element holding the SKU text, e.g. "SKU: sw2208123456789".
  static const List<String> sku = [
    '.product-intro__head-sku',
    '[class*="head-sku"]',
    '[class*="goods-sn"]',
    '[class*="sku-code"]',
  ];

  /// All size options on the page (used to know whether a size is required).
  static const List<String> sizeOptions = [
    '.product-intro__size-radio',
    '.product-intro__sizes-item',
    '.goods-size__sizes-item',
    '[class*="size-radio"]',
    '[class*="sizes-item"]',
  ];

  /// The currently selected size option.
  static const List<String> selectedSize = [
    '.product-intro__size-radio_active',
    '.product-intro__sizes-item.active',
    '.goods-size__sizes-item.size-active',
    '[class*="size-radio_active"]',
    '[class*="sizes-item"][class*="active"]',
  ];

  /// The currently selected color swatch.
  static const List<String> selectedColor = [
    '.product-intro__color-radio_active',
    '.product-intro__color-block_active',
    '.goods-color__item.color-active',
    '[class*="color-radio_active"]',
    '[class*="color-item"][class*="active"]',
  ];

  /// Label like "اللون: أسود" used as a last fallback for the color.
  static const List<String> colorLabel = [
    '.product-intro__color-title',
    '.goods-color__title',
    '[class*="color-title"]',
  ];

  // ---------------------------------------------------------------------------
  // Shared cart page (cart link pasted by the user)
  // ---------------------------------------------------------------------------

  static final RegExp sharedCartUrlPattern = RegExp(
    r'(/cart|cart[_-]?share|share[_-]?cart|/share/|sharejump|/bag)',
    caseSensitive: false,
  );

  static const List<String> cartItem = [
    '.j-cart-item',
    '.cart-item',
    '[class*="cartItem"]',
    '[class*="cart-item"]',
    '[data-goods-id]',
  ];

  static const List<String> cartItemTitle = [
    '[class*="goods-name"]',
    '[class*="goods-title"]',
    '[class*="item-name"]',
    '[class*="name"]',
  ];

  static const List<String> cartItemPrice = [
    '[class*="sale-price"]',
    '[class*="price-sale"]',
    '[class*="goods-price"]',
    '[class*="price"]',
  ];

  static const List<String> cartItemAttr = [
    '[class*="goods-attr"]',
    '[class*="sku-attr"]',
    '[class*="attr"]',
  ];

  static const List<String> cartItemQuantity = [
    'input[type="number"]',
    '[class*="quantity"]',
    '[class*="qty"]',
    '[class*="num"]',
  ];

  static const String cartExcludeClassPattern =
      'recommend|you-?may|similar|guess|rec-|related';

  // ---------------------------------------------------------------------------
  // SHEIN's own purchase UI that must be hidden
  // ---------------------------------------------------------------------------

  /// SHEIN's native "Add to bag" buttons (hidden with CSS).
  static const List<String> nativeAddToCart = [
    '.product-intro__add-btn',
    '.product-intro__add-cart',
    '.add-cart__btn',
    '.goods-btn__add',
    '.j-add-cart',
    '[class*="add-cart-btn"]',
    '[class*="addCartBtn"]',
    '[class*="add-bag"]',
    '[class*="add-all"]',
    '[class*="addAll"]',
    '[class*="all-add"]',
  ];

  /// Sticky bottom purchase bars (hidden with CSS).
  static const List<String> stickyPurchaseBar = [
    '.product-intro__fixed-bottom',
    '.product-intro__add-cart-sticky',
    '.add-cart__fixed',
    '.goods-detail__fixed-bottom',
    '[class*="addcart-fixed"]',
    '[class*="sticky-add"]',
  ];

  /// Visible texts of SHEIN's add-to-bag buttons. Matching ignores case,
  /// extra spaces and Alef/Yaa variants (أ/إ/آ → ا, ى → ي).
  static const List<String> nativeButtonTexts = [
    'أضف إلى الحقيبة',
    'إضافة إلى الحقيبة',
    'أضف إلى عربة التسوق',
    'أضف إلى السلة',
    'Add to Bag',
    'Add to Cart',
    'إضافة الكل إلى عربة التسوق',
    'اضافة الكل إلى عربة التسوق',
    'أضف الكل إلى عربة التسوق',
    'إضافة الكل إلى السلة',
    'أضف الكل إلى السلة',
    'إضافة الكل إلى الحقيبة',
    'أضف الكل إلى الحقيبة',
    'Add All to Cart',
    'Add All to Bag',
  ];

  /// Elements whose text is checked against [nativeButtonTexts].
  static const List<String> textMatchCandidates = [
    'button',
    '[role="button"]',
    'a',
    '[class*="btn"]',
  ];

  /// Elements with longer text are never hidden by text matching
  /// (protects containers that merely *contain* a button).
  static const int maxButtonTextLength = 40;
}
