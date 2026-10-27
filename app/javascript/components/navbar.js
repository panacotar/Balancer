const initUpdateNavbarOnScroll = () => {
  const navbar = document.querySelector('.navbar-lewagon');
  if (navbar) {
    window.addEventListener('scroll', () => {
      if (window.scrollY) {
        navbar.classList.add('navbar-lewagon-yellow');
      } else {
        navbar.classList.remove('navbar-lewagon-yellow');
      }
    });
  }
}

export { initUpdateNavbarOnScroll };
