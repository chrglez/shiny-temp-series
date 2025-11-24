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
});

// Handler para Shiny
$(document).on('shiny:connected', function() {
  console.log('Shiny connected');
});

// Comunicación con Shiny
Shiny.addCustomMessageHandler('showNotification', function(data) {
  showNotification(data.message, data.type);
});
