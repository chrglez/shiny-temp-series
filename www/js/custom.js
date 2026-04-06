// JavaScript personalizado para la aplicación

// Función para mostrar notificaciones
function showNotification(message, type = 'info') {
  const notification = document.createElement('div');
  notification.className = `alert alert-${type} alert-dismissible fade show`;
  notification.innerHTML = `
    ${message}
    <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
  `;

  const container = document.querySelector('.container-fluid') || document.body;
  container.insertBefore(notification, container.firstChild);

  // Auto-dismiss después de 5 segundos
  setTimeout(() => {
    notification.remove();
  }, 5000);
}

// Función para confirmar acciones
function confirmAction(message) {
  return confirm(message);
}

// Inicialización cuando el DOM está listo
$(document).ready(function() {
  // Añadir clase fade-in a las cards
  $('.card').addClass('fade-in');

  // Tooltips de Bootstrap
  var tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
  var tooltipList = tooltipTriggerList.map(function (tooltipTriggerEl) {
    return new bootstrap.Tooltip(tooltipTriggerEl);
  });
  
  // OBSERVER para detectar cambios en el body (Bootstrap modal)
  const bodyObserver = new MutationObserver(function(mutations) {
    mutations.forEach(function(mutation) {
      if (mutation.type === 'attributes' && mutation.attributeName === 'style') {
        const bodyPaddingRight = $('body').css('padding-right');
        if (bodyPaddingRight && bodyPaddingRight !== '0px') {
          console.log('⚠️ Body padding-right detected:', bodyPaddingRight);
          // Aplicar fix inmediatamente
          setTimeout(forceLayoutFix, 10);
        }
      }
    });
  });
  
  // Observar cambios en el body
  bodyObserver.observe(document.body, {
    attributes: true,
    attributeFilter: ['style', 'class']
  });
  
  console.log('👁️ Body observer initialized');
});

// Handler para Shiny
$(document).on('shiny:connected', function() {
  console.log('Shiny connected');
  
  // CRITICAL FIX: Forzar layout correcto
  forceLayoutFix();
});

// CRITICAL FIX: Función para forzar que el layout se mantenga correcto
function forceLayoutFix() {
  const main = $('.bslib-sidebar-layout > .main');
  const layout = $('.bslib-sidebar-layout');
  const sidebar = $('.bslib-sidebar-layout > .sidebar');
  
  if (main.length > 0) {
    // Remover cualquier estilo inline que Shiny/Bootstrap pueda agregar
    main.css({
      'flex': '1 1 auto',
      'width': 'auto',
      'max-width': 'none',
      'min-width': '0',
      'margin-right': '0',
      'padding-right': '0'
    });
    
    // Forzar sidebar a mantener su ancho
    sidebar.css({
      'flex': '0 0 250px',
      'min-width': '250px',
      'max-width': '250px',
      'margin-right': '0',
      'padding-right': '0'
    });
    
    // Asegurar que layout mantiene ancho completo
    layout.css({
      'width': '100%',
      'max-width': '100%',
      'margin-right': '0',
      'padding-right': '0'
    });
    
    // Asegurar que layout no tiene clases problemáticas
    layout.removeClass('sidebar-collapsed');
    
    // Remover padding-right del body que Bootstrap modal puede agregar
    if (!$('.modal.show').length) {
      $('body').css('padding-right', '0');
    }
    
    console.log('✅ Layout fix applied');
  }
}

// Aplicar fix después de cada actualización de Shiny
$(document).on('shiny:value', function(event) {
  setTimeout(forceLayoutFix, 50);
});

$(document).on('shiny:inputchanged', function(event) {
  setTimeout(forceLayoutFix, 50);
});

$(document).on('shiny:outputinvalidated', function(event) {
  setTimeout(forceLayoutFix, 50);
});

// Función para forzar ocultar el overlay y restaurar el botón
function forceHideOverlay() {
  // Limpiar timeout
  if (analysisTimeout) {
    clearTimeout(analysisTimeout);
    analysisTimeout = null;
  }
  
  // Ocultar overlay
  $('#loading-overlay').removeClass('active');
  
  // Restaurar botón
  const btn = $('#runAnalysis');
  btn.prop('disabled', false);
  btn.html('<i class="fa fa-play"></i> Run Analysis');
  btn.css('opacity', '1');
  
  // Cerrar acordeones de configuración
  setTimeout(function() {
    // Cerrar todos los paneles del accordion
    $('#configAccordion .accordion-collapse.show').removeClass('show');
    console.log('📁 Configuration accordions collapsed');
  }, 200);
  
  // Resetear flag
  analysisInProgress = false;
  
  console.log('🏁 Analysis finished - overlay hidden');
}

// Variables para controlar el estado del análisis
let analysisInProgress = false;
let analysisTimeout = null;

// Indicador de carga para Run Analysis
$(document).on('click', '#runAnalysis', function() {
  const btn = $(this);
  
  // Limpiar timeout anterior si existe
  if (analysisTimeout) {
    clearTimeout(analysisTimeout);
  }
  
  // Marcar que el análisis está en progreso
  analysisInProgress = true;
  
  // Mostrar overlay de carga
  $('#loading-overlay').addClass('active');
  
  // Cambiar botón a estado de carga
  btn.prop('disabled', true);
  btn.html('<i class="fa fa-spinner fa-spin"></i> Analyzing...');
  btn.css('opacity', '0.7');
  
  console.log('🔄 Analysis started - waiting for Shiny idle...');
  
  // Timeout de seguridad amplio (5 minutos — el análisis con MC puede tardar)
  analysisTimeout = setTimeout(function() {
    console.warn('Safety timeout - forcing overlay hide after 5 minutes');
    forceHideOverlay();
  }, 300000);
});

// Detectar cuando Shiny está ocupado procesando
$(document).on('shiny:busy', function(event) {
  console.log('⏳ Shiny is busy...');
  $('body').addClass('shiny-busy-indicator');
  
  // Si el análisis está en progreso, asegurar que overlay está visible
  if (analysisInProgress) {
    $('#loading-overlay').addClass('active');
  }
});

$(document).on('shiny:idle', function(event) {
  console.log('✅ Shiny is idle');
  $('body').removeClass('shiny-busy-indicator');
  
  // Si hay un análisis en progreso, ocultarlo INMEDIATAMENTE cuando Shiny esté idle
  if (analysisInProgress) {
    console.log('🏁 Shiny idle detected - hiding overlay NOW (not waiting for outputs)');
    
    // Ocultar overlay inmediatamente sin esperar outputs
    forceHideOverlay();
    
    // Scroll suave hacia "View Results" cuando aparezca
    setTimeout(function() {
      const resultsSelector = $('#resultsSelector');
      if (resultsSelector.length && resultsSelector.is(':visible')) {
        resultsSelector[0].scrollIntoView({ 
          behavior: 'smooth', 
          block: 'nearest' 
        });
        console.log('📍 Scrolled to View Results');
      }
    }, 300);
  }
});

// FIX para modales - Bootstrap puede modificar el body
$(document).on('show.bs.modal', function() {
  console.log('📢 Modal opening - applying layout fix');
  setTimeout(forceLayoutFix, 100);
});

$(document).on('shown.bs.modal', function() {
  console.log('📢 Modal opened - applying layout fix');
  forceLayoutFix();
});

$(document).on('hide.bs.modal', function() {
  console.log('📢 Modal closing - applying layout fix');
  setTimeout(forceLayoutFix, 100);
});

$(document).on('hidden.bs.modal', function() {
  console.log('📢 Modal closed - applying layout fix');
  forceLayoutFix();
  
  // Fix adicional después de que el modal se cierra completamente
  setTimeout(forceLayoutFix, 300);
});

// Comunicación con Shiny
Shiny.addCustomMessageHandler('showNotification', function(data) {
  showNotification(data.message, data.type);
});
