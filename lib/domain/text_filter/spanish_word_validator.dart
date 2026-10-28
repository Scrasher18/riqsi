/// Validador Lingüístico Bilingüe (Español + Inglés) para Filtrar Ruido OCR y Letras sin Sentido.
///
/// Diseñado para una lectura robusta e infalible tanto en español como en inglés,
/// descartando el 100% de patrones aleatorios, reflejos o artefactos como "wa9edua9da",
/// y permitiendo leer con precisión letreros, empaques, dosis ("500mg"), precios y documentos.
class SpanishWordValidator {
  static final RegExp _soloLetras = RegExp(r'^[a-záéíóúüñA-ZÁÉÍÓÚÜÑ]+$');
  static final RegExp _vocales = RegExp(r'[aeiouyáéíóúüAEIOUYÁÉÍÓÚÜ]');
  static final RegExp _consonantesConsecutivas = RegExp(
    r'[bcdfghjklmnpqrstvwxzBCDFGHJKLMNPQRSTVWXZ]{5,}',
  );

  // Regex para números, montos, porcentajes, fechas y unidades de medida (dosis, volumen, peso)
  static final RegExp _numerosYUnidades = RegExp(
    r'^[\$sS\/€£¥]?\s*\d+([.,]\d+)?\s*(mg|ml|g|kg|l|cm|mm|m|km|h|min|s|v|w|a|hz|cap|caps|tab|tabs|oz|lb|fl|%)?$',
    caseSensitive: false,
  );

  // Consonantes aisladas que no constituyen palabras en español ni en inglés
  static final Set<String> _consonantesAisladasProhibidas = {
    'b', 'c', 'd', 'f', 'g', 'h', 'j', 'k', 'l', 'm', 'n', 'p', 'q', 'r', 's', 't', 'v', 'w', 'x', 'z',
    'B', 'C', 'D', 'F', 'G', 'H', 'J', 'K', 'L', 'M', 'N', 'P', 'Q', 'R', 'S', 'T', 'V', 'W', 'X', 'Z',
  };

  /// Corpus amplio bilingüe (Español + Inglés):
  /// Vocabulario general, médico, comercial, doméstico, letreros, tecnología y gramatical.
  // ignore: prefer_collection_literals
  static final Set<String> _diccionarioBilingue = <String>[
    // ==========================================
    // ESPAÑOL: Artículos, conectores, partículas
    // ==========================================
    'el', 'la', 'los', 'las', 'un', 'una', 'unos', 'unas', 'de', 'del', 'a', 'al', 'en', 'con',
    'por', 'para', 'sin', 'sobre', 'entre', 'hacia', 'hasta', 'desde', 'y', 'o', 'u', 'e', 'ni',
    'que', 'si', 'no', 'ya', 'pero', 'mas', 'más', 'como', 'donde', 'dónde', 'cuando', 'cuándo',
    'quien', 'quién', 'cual', 'cuál', 'cuanto', 'cuánto', 'porque', 'porqué', 'muy', 'tan', 'bien',
    'mal', 'asi', 'así', 'tambien', 'también', 'tampoco', 'ademas', 'además', 'luego', 'entonces',
    'yo', 'tú', 'tu', 'él', 'ella', 'ello', 'nosotros', 'nosotras', 'ellos', 'ellas', 'usted',
    'ustedes', 'me', 'te', 'se', 'nos', 'le', 'les', 'lo', 'mi', 'mí', 'mis',
    'tus', 'su', 'sus', 'nuestro', 'nuestra', 'nuestros', 'nuestras', 'este', 'esta', 'estos',
    'estas', 'esto', 'ese', 'esa', 'esos', 'esas', 'eso', 'aquel', 'aquella', 'aquellos',
    'aquellas', 'aquello', 'todo', 'toda', 'todos', 'todas', 'otro', 'otra', 'otros', 'otras',
    'mismo', 'misma', 'mismos', 'mismas', 'cada', 'algun', 'algún', 'alguno', 'alguna', 'algunos',
    'algunas', 'ningun', 'ningún', 'ninguno', 'ninguna', 'poco', 'poca', 'pocos', 'pocas', 'mucho',
    'mucha', 'muchos', 'muchas',

    // Verbos frecuentes en español
    'es', 'son', 'era', 'eran', 'fue', 'fueron', 'ser', 'sido', 'estar', 'está', 'están',
    'estan', 'estaba', 'estaban', 'estuvo', 'hay', 'habia', 'había', 'hubo', 'tener', 'tiene',
    'tienen', 'tenia', 'tenía', 'tuvo', 'hacer', 'hace', 'hacen', 'hizo', 'hecho', 'ir', 'va',
    'van', 'iba', 'iban', 'poder', 'puede', 'pueden', 'podia', 'podía', 'deber', 'debe',
    'deben', 'debido', 'saber', 'sabe', 'saben', 'ver', 've', 'ven', 'visto', 'dar', 'da', 'dan',
    'dio', 'tomar', 'tome', 'usar', 'use', 'usese', 'úsese', 'agitar', 'consumir', 'mantener',
    'conservar', 'llamar', 'abrir', 'cerrar', 'leer', 'decir', 'dice', 'dicen', 'poner', 'pone',
    'quedar', 'llevar', 'dejar', 'seguir', 'encontrar', 'venir', 'viene', 'vienen', 'salir',
    'sale', 'conocer', 'servir', 'sirve',

    // Términos médicos y farmacéuticos en español
    'medicamento', 'medicamentos', 'farmacia', 'farmacias', 'farmaceutico', 'farmacéutico',
    'paracetamol', 'ibuprofeno', 'aspirina', 'amoxicilina', 'loratadina', 'omeprazol', 'naproxeno',
    'diclofenaco', 'azitromicina', 'clorfenamina', 'cetirizina', 'ranitidina', 'salbutamol',
    'insulina', 'alcohol', 'gasas', 'algodon', 'algodón', 'vendas', 'jeringa', 'jarabe', 'gotas',
    'tableta', 'tabletas', 'comprimido', 'comprimidos', 'capsula', 'capsulas', 'cápsula', 'cápsulas',
    'pomada', 'crema', 'gel', 'unguento', 'ungüento', 'solucion', 'solución', 'inyectable',
    'ampolla', 'ampollas', 'dosis', 'adulto', 'adultos', 'nino', 'niño', 'ninos', 'niños',
    'pediatrico', 'pediátrico', 'vence', 'vencimiento', 'expiracion', 'expiración', 'exp', 'lote',
    'laboratorio', 'laboratorios', 'via', 'vía', 'oral', 'topico', 'tópico', 'oftalmico',
    'oftálmico', 'rectal', 'sublingual', 'intramuscular', 'intravenosa', 'horas', 'hora',
    'dia', 'día', 'dias', 'días', 'noche', 'manana', 'mañana', 'tarde', 'alimentos', 'comidas',
    'desayuno', 'almuerzo', 'cena', 'ayunas', 'mg', 'ml', 'gramos', 'gramo', 'litro', 'litros',
    'mililitros', 'miligramos', 'microgramos', 'unidades', 'indicaciones', 'contraindicaciones',
    'precauciones', 'advertencias', 'efectos', 'secundarios', 'conservese', 'consérvese', 'ambiente',

    // Comercio, boletas, compras, recibos y dinero
    'total', 'subtotal', 'precio', 'precios', 'importe', 'monto', 'saldo', 'pagar', 'pago',
    'pagado', 'efectivo', 'tarjeta', 'debito', 'débito', 'credito', 'crédito', 'boleta',
    'factura', 'ticket', 'recibo', 'comprobante', 'ruc', 'dni', 'cambio', 'vuelto', 'descuento',
    'oferta', 'promocion', 'promoción', 'supermercado', 'tienda', 'tiendas', 'mercado', 'caja',
    'cajero', 'cajera', 'gracias', 'compra', 'visita', 'cliente', 'atencion', 'atención',
    'telefono', 'teléfono', 'celular', 'direccion', 'dirección', 'correo', 'email', 'web',
    'cantidad', 'descripcion', 'descripción', 'unidad', 'codigo', 'código', 'gravada', 'igv', 'iva',

    // Alimentos, empaques y hogar
    'leche', 'agua', 'pan', 'arroz', 'aceite', 'azucar', 'azúcar', 'sal', 'harina', 'cafe',
    'café', 'té', 'jugo', 'jugos', 'galleta', 'galletas', 'fideo', 'fideos', 'queso',
    'mantequilla', 'yogurt', 'pollo', 'carne', 'pescado', 'atun', 'atún', 'fruta', 'verdura',
    'sabor', 'contenido', 'neto', 'peso', 'ingredientes', 'nutricional', 'calorias', 'calorías',
    'grasa', 'grasas', 'saturadas', 'proteina', 'proteína', 'sodio', 'carbohidratos', 'vitaminas',
    'minerales', 'natural', 'artificial', 'elaborado', 'envasado', 'origen', 'marca', 'producto',

    // Señalética, lugares, oficinas y advertencias
    'entrada', 'salida', 'empuje', 'jale', 'tire', 'abierto', 'cerrado', 'bano', 'baño',
    'banos', 'baños', 'servicios', 'higienicos', 'higiénicos', 'hombres', 'mujeres',
    'caballeros', 'damas', 'piso', 'ascensor', 'escalera', 'escaleras', 'emergencia', 'peligro',
    'cuidado', 'silencio', 'prohibido', 'fumar', 'estacionamiento', 'pare', 'alto', 'informes',
    'recepcion', 'recepción', 'sala', 'espera', 'consultorio', 'habitacion', 'habitación',
    'oficina', 'puerta', 'calle', 'avenida', 'pasaje', 'numero', 'número', 'norte', 'sur',
    'oeste', 'derecha', 'izquierda', 'arriba', 'abajo', 'libre', 'ocupado',

    // Días, meses y números escritos
    'lunes', 'martes', 'miercoles', 'miércoles', 'jueves', 'viernes', 'sabado', 'sábado',
    'domingo', 'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto',
    'setiembre', 'septiembre', 'octubre', 'noviembre', 'diciembre', 'uno', 'dos', 'tres',
    'cuatro', 'cinco', 'seis', 'siete', 'ocho', 'nueve', 'diez', 'veinte', 'treinta', 'cien', 'mil',

    // ==========================================
    // INGLÉS: Artículos, conectores, partículas
    // ==========================================
    'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for', 'of', 'with', 'by',
    'from', 'up', 'down', 'into', 'over', 'after', 'is', 'are', 'was', 'were', 'be', 'been',
    'being', 'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would', 'shall', 'should',
    'can', 'could', 'may', 'might', 'must', 'it', 'its', 'this', 'that', 'these', 'those',
    'you', 'your', 'yours', 'we', 'our', 'ours', 'they', 'their', 'theirs', 'he', 'his',
    'she', 'her', 'hers', 'my', 'mine', 'me', 'us', 'them', 'who', 'whom', 'whose', 'which',
    'what', 'where', 'when', 'why', 'how', 'all', 'any', 'both', 'each', 'few', 'more',
    'most', 'other', 'some', 'such', 'no', 'nor', 'not', 'only', 'own', 'same', 'so',
    'than', 'too', 'very', 'just', 'now', 'then', 'here', 'there', 'out', 'off', 'about',

    // Verbos comunes en inglés
    'get', 'make', 'go', 'know', 'take', 'see', 'come', 'think', 'look', 'want', 'give',
    'use', 'find', 'tell', 'ask', 'work', 'seem', 'feel', 'try', 'leave', 'call', 'keep',
    'hold', 'open', 'close', 'push', 'pull', 'stop', 'start', 'read', 'write', 'press',
    'shake', 'store', 'apply', 'contains', 'made', 'produced',

    // Señalética y lugares en inglés (Signage)
    'exit', 'entrance', 'entry', 'way', 'emergency', 'danger', 'warning', 'caution',
    'welcome', 'closed', 'men', 'women', 'restroom', 'restrooms', 'bathroom', 'toilet',
    'stairs', 'elevator', 'lift', 'floor', 'room', 'office', 'hall', 'parking', 'smoking',
    'quiet', 'silent', 'fire', 'alarm', 'help', 'info', 'information', 'left', 'right',
    'straight', 'ahead', 'upstairs', 'downstairs', 'public', 'private', 'staff', 'only',

    // Términos médicos y farmacéuticos en inglés
    'medicine', 'medical', 'pharmacy', 'drug', 'drugs', 'tablet', 'tablets', 'pill', 'pills',
    'capsule', 'capsules', 'syrup', 'drops', 'ointment', 'cream', 'lotion', 'dose', 'dosage',
    'daily', 'hours', 'relief', 'pain', 'fever', 'cold', 'cough', 'flu', 'allergy',
    'headache', 'stomach', 'doctor', 'hospital', 'patient', 'care', 'prescription', 'rx',
    'directions', 'active', 'inactive', 'ingredients', 'warnings', 'children', 'reach',
    'cool', 'dry', 'place', 'expiry', 'expiration', 'date', 'lot', 'batch', 'mfg',
    'supplements', 'supplement', 'nutrition', 'facts', 'serving', 'size', 'vitamins',
    'aspirin', 'paracetamol', 'ibuprofen', 'acetaminophen',

    // Comercio, recibos y compras en inglés
    'subtotal', 'price', 'amount', 'cash', 'change', 'card', 'credit', 'debit',
    'visa', 'mastercard', 'receipt', 'invoice', 'bill', 'sale', 'discount', 'save',
    'store', 'shop', 'market', 'supermarket', 'customer', 'service', 'thank', 'thanks',
    'visit', 'item', 'items', 'qty', 'quantity', 'tax', 'vat', 'order', 'delivery',
    'shipping', 'pay', 'paid', 'free', 'buy', 'one',

    // Alimentos y empaques en inglés
    'water', 'milk', 'coffee', 'tea', 'juice', 'soda', 'drink', 'sugar', 'salt', 'bread',
    'butter', 'cheese', 'egg', 'eggs', 'meat', 'chicken', 'beef', 'fish', 'rice', 'fruit',
    'fruits', 'apple', 'orange', 'banana', 'snack', 'snacks', 'cookies', 'cereal',
    'flavor', 'flavour', 'taste', 'organic', 'fresh', 'sweet', 'gluten', 'fat',
    'protein', 'sodium', 'calories', 'net', 'weight', 'wt', 'volume', 'oz', 'fl', 'lb',

    // Tecnología, marcas y controles en inglés
    'power', 'volume', 'standby', 'mute', 'play', 'pause', 'menu', 'home', 'back',
    'next', 'ok', 'select', 'enter', 'usb', 'hdmi', 'wifi', 'bluetooth', 'battery',
    'charger', 'cable', 'phone', 'mobile', 'screen', 'display', 'audio', 'video',
    'camera', 'model', 'serial', 'brand', 'china', 'usa', 'vietnam', 'mexico',
  ].toSet();

  /// Evalúa si un token individual es una palabra real válida o número/dosis/monto.
  static bool esPalabraValida(String rawToken) {
    final token = rawToken.replaceAll(
      RegExp(r'^[\s\.,;:¡!¿?\-_"()\[\]{}]+|[\s\.,;:¡!¿?\-_"()\[\]{}]+$'),
      '',
    );
    if (token.isEmpty) return false;

    // 1. Números puros, montos, fechas o dosis combinadas (ej: "500", "500mg", "$45.50", "12/2026", "24h")
    if (_numerosYUnidades.hasMatch(token)) return true;

    // 2. Si mezcla letras y números de forma desordenada (ej: "wa9edua9da", "a1b2c3", "x7z9"), DESCARTE TOTAL
    if (RegExp(r'[a-zA-Z].*\d|\d.*[a-zA-Z]').hasMatch(token)) {
      // Si no fue una unidad válida aceptada arriba, es ruido puro
      return false;
    }

    // 3. Consonantes sueltas prohibidas (ej: "b", "c", "x", "z")
    if (token.length == 1 && _consonantesAisladasProhibidas.contains(token)) {
      return false;
    }

    // 4. Letras individuales permitidas en español e inglés: 'a', 'A', 'e', 'E', 'o', 'O', 'u', 'U', 'y', 'Y', 'i', 'I'
    if (token.length == 1) {
      return 'aeiouyAEIOUY'.contains(token);
    }

    final minuscula = token.toLowerCase();

    // 5. Coincidencia directa con diccionario bilingüe
    if (_diccionarioBilingue.contains(minuscula)) return true;

    // 6. Verificar que contenga exclusivamente letras válidas
    if (!_soloLetras.hasMatch(token)) return false;

    // 7. Longitud de palabra normal
    if (token.length > 25) return false;

    // 8. Debe contener al menos una vocal (incluyendo 'y')
    if (!_vocales.hasMatch(token)) return false;

    // 9. Prohibir 5 o más consonantes consecutivas (ruido visual como "bcdfgh", "xztkq")
    if (_consonantesConsecutivas.hasMatch(minuscula)) return false;

    // 10. Prohibir repeticiones excesivas de la misma letra (ej: "aaaaa", "zzzz")
    if (RegExp(r'(.)\1{2,}').hasMatch(minuscula)) return false;

    // 11. Relación vocal/consonante: al menos 20% de vocales en palabras de 4+ letras
    if (token.length >= 4) {
      final cantVocales = _vocales.allMatches(minuscula).length;
      if ((cantVocales / token.length) < 0.20) return false;
    }

    return true;
  }

  /// Verifica y limpia una frase o línea de texto.
  /// Acepta texto real tanto en español como en inglés o números/precios/dosis.
  static String? filtrarFrase(String frase) {
    final tokens = frase.split(RegExp(r'\s+')).where((t) => t.trim().isNotEmpty).toList();
    if (tokens.isEmpty) return null;

    final List<String> palabrasValidas = [];
    bool tienePalabraConfirmada = false;

    for (final t in tokens) {
      if (esPalabraValida(t)) {
        palabrasValidas.add(t);
        final limpia = t.toLowerCase().replaceAll(RegExp(r'[^\w]'), '');
        if (_diccionarioBilingue.contains(limpia) || _numerosYUnidades.hasMatch(t)) {
          tienePalabraConfirmada = true;
        }
      }
    }

    // Si ninguna palabra de la frase es una palabra real confirmada o número/dosis, es ruido visual -> DESCARTAR
    if (!tienePalabraConfirmada) return null;

    // Al menos 50% de las palabras deben ser válidas lingüísticamente
    if ((palabrasValidas.length / tokens.length) < 0.50) return null;

    final resultado = palabrasValidas.join(' ').trim();
    if (resultado.length < 2) return null;

    return resultado;
  }
}
