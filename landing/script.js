document.addEventListener('DOMContentLoaded', () => {
  const hamburger = document.querySelector('.hamburger');
  const mobileMenu = document.querySelector('.mobile-menu');
  const closeMenu = document.querySelector('.close-menu');
  const overlay = document.querySelector('.menu-overlay');

  function toggleMenu() {
    mobileMenu.classList.toggle('active');
    overlay.classList.toggle('active');
    document.body.classList.toggle('no-scroll');
  }

  hamburger.addEventListener('click', toggleMenu);
  closeMenu.addEventListener('click', toggleMenu);
  overlay.addEventListener('click', toggleMenu);

  // Close menu when clicking a link
  mobileMenu.querySelectorAll('.nav-link').forEach(link => {
    link.addEventListener('click', toggleMenu);
  });

  // Language Switcher Logic
  const currentLang = document.documentElement.lang || 'en';
  const langLinks = document.querySelectorAll('.lang-switcher a');

  langLinks.forEach(link => {
    const lang = link.getAttribute('data-lang');
    if (lang === currentLang) {
      link.classList.add('active');
    }

    link.addEventListener('click', (e) => {
      e.preventDefault();
      if (lang === currentLang) return;

      localStorage.setItem('selected-lang', lang);
      // Redirect to the same path but in the other language
      // Example: project.com/landing/dist/es/index.html -> project.com/landing/dist/en/index.html
      const newPath = window.location.pathname.replace(`/${currentLang}/`, `/${lang}/`);
      window.location.href = newPath + window.location.hash;
    });
  });
});
