window.forceNumericInput = function () {
  setTimeout(function () {
    var active = document.activeElement;
    if (active && active.tagName === 'INPUT') {
      // Function to enforce attributes
      var enforce = function () {
        if (active.getAttribute('inputmode') !== 'decimal') {
          active.setAttribute('inputmode', 'decimal');
        }
        if (active.getAttribute('pattern') !== '[0-9]*') {
          active.setAttribute('pattern', '[0-9]*');
        }
        // Do NOT set type='number' as it messes with cursor selection
      };

      // Apply immediately
      enforce();

      // Watch for changes (Flux/Flutter might revert them)
      var observer = new MutationObserver(function (mutations) {
        enforce();
      });

      observer.observe(active, {
        attributes: true,
        attributeFilter: ['inputmode', 'pattern', 'type']
      });

      // Disconnect observer when element loses focus
      active.addEventListener('blur', function () {
        observer.disconnect();
      }, { once: true });
    }
  }, 100);
};
