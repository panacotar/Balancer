import Rails from '@rails/ujs';
import Turbolinks from 'turbolinks';
import * as ActiveStorage from '@rails/activestorage';
import './jquery';
import 'bootstrap';
import 'slick-carousel';
import flatpickr from 'flatpickr';
import AOS from 'aos';
import { makeChart } from './components/chart';
import { initUpdateNavbarOnScroll } from './components/navbar';
import { initSlick } from './components/carousel';

Rails.start();
Turbolinks.start();
ActiveStorage.start();

let disposeChart;
document.addEventListener('turbolinks:load', () => {
  if (document.getElementById('chartdiv')) disposeChart = makeChart('chartdiv');
  initUpdateNavbarOnScroll();
  initSlick();
  AOS.init();
  const oldestBirthday = new Date();
  oldestBirthday.setFullYear(oldestBirthday.getFullYear() - 15);
  flatpickr('.date-picker', { altInput: true, altFormat: 'F j, Y', dateFormat: 'Y-m-d', maxDate: oldestBirthday });
  flatpickr('.campaign-date-picker', { enableTime: true, time_24hr: true, dateFormat: 'Y-m-d H:i', minDate: new Date() });
});

document.addEventListener('turbolinks:before-cache', () => {
  disposeChart?.();
  disposeChart = undefined;
  document.querySelectorAll('.flatpickr-input').forEach(input => input._flatpickr?.destroy());
  $('.responsive.slick-initialized').slick('unslick');
});
