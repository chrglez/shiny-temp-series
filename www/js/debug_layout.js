// Script de debug para identificar problemas de layout

$(document).ready(function() {
  console.log('Debug Layout Script Loaded');
  
  // Función para verificar anchos
  function checkLayoutWidths() {
    const sidebar = $('.bslib-sidebar-layout > .sidebar');
    const main = $('.bslib-sidebar-layout > .main');
    const layout = $('.bslib-sidebar-layout');
    const cards = $('.card');
    const tabContent = $('.tab-content');
    const tabPane = $('.tab-pane.active');
    
    console.log('=== LAYOUT DEBUG ===');
    console.log('Layout width:', layout.width());
    console.log('Layout classes:', layout.attr('class'));
    console.log('Sidebar width:', sidebar.width());
    console.log('Sidebar classes:', sidebar.attr('class'));
    console.log('Main width:', main.width());
    console.log('Main classes:', main.attr('class'));
    console.log('Main computed style:', window.getComputedStyle(main[0]).flex);
    
    // Verificar si hay clases que modifiquen el layout
    if (layout.hasClass('sidebar-collapsed')) {
      console.warn('⚠️ WARNING: sidebar-collapsed class detected!');
    }
    if (layout.attr('class').includes('sidebar-')) {
      console.warn('⚠️ WARNING: Additional sidebar class detected:', layout.attr('class'));
    }
    
    // Verificar elementos hijos
    console.log('--- Children Elements ---');
    console.log('Tab-content width:', tabContent.width());
    console.log('Active tab-pane width:', tabPane.width());
    console.log('Number of cards:', cards.length);
    cards.each(function(i) {
      console.log('Card ' + i + ' width:', $(this).width());
    });
    
    // Verificar dygraphs y otros elementos específicos
    const dygraphs = $('.dygraph-plot');
    const cardBodies = $('.card-body');
    console.log('--- Specific Elements ---');
    console.log('Number of dygraphs:', dygraphs.length);
    dygraphs.each(function(i) {
      console.log('Dygraph ' + i + ' width:', $(this).width());
    });
    console.log('Number of card-bodies:', cardBodies.length);
    cardBodies.each(function(i) {
      const width = $(this).width();
      const padding = $(this).css('padding');
      console.log('Card-body ' + i + ' width:', width, 'padding:', padding);
    });
    console.log('===================');
  }
  
  // Verificar al cargar
  setTimeout(checkLayoutWidths, 1000);
  
  // Verificar cuando se hace clic en cualquier botón
  $(document).on('click', 'button, .btn', function(e) {
    console.log('Button clicked:', $(this).text());
    setTimeout(checkLayoutWidths, 500);
  });
  
  // Observar cambios en el DOM
  const observer = new MutationObserver(function(mutations) {
    mutations.forEach(function(mutation) {
      if (mutation.type === 'attributes' && 
          (mutation.attributeName === 'style' || mutation.attributeName === 'class')) {
        console.log('Style/class changed on:', mutation.target);
        checkLayoutWidths();
      }
    });
  });
  
  // Observar el main container
  const mainContainer = document.querySelector('.bslib-sidebar-layout > .main');
  if (mainContainer) {
    observer.observe(mainContainer, {
      attributes: true,
      attributeFilter: ['style', 'class']
    });
  }
});
