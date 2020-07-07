const showOnScroll = () => {

const img = document.getElementById("appearOnScroll");

if (img) {
    window.addEventListener('scroll', () => {
      if (window.scrollY > 2*window.innerHeight) {
        img.classList.remove('hidden');
      } else {
        img.classList.add('hidden');
      }
    });
  }

}

export { showOnScroll };
