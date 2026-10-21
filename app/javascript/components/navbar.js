const initUpdateNavbarOnScroll = () => {
  window.onscroll = () => {
    document.querySelector('.navbar-lewagon')?.classList.toggle('navbar-lewagon-yellow', window.scrollY > 0);
  };
  window.onscroll();
};
export { initUpdateNavbarOnScroll };
