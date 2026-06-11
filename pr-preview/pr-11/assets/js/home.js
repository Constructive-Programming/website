/* Landing page motion — GSAP + ScrollTrigger (loaded via CDN, defer).
 *
 * Design constraints:
 *  - Content is fully visible without JS; this file only ADDS motion.
 *  - prefers-reduced-motion: no entrances, no parallax, no canvas.
 *  - Canvas pauses when the hero is off-screen or the tab is hidden.
 */
(function () {
  'use strict';

  var reduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  var home = document.querySelector('.cp-home');
  if (!home) return;

  /* ---------------------------------------------------- Canvas */
  // A sparse field of drifting nodes; near nodes get a connecting
  // line. Reads as "flowing logic" without demanding attention.
  function startFlowField() {
    var canvas = document.getElementById('hp-flow');
    if (!canvas) return;
    var ctx = canvas.getContext('2d');
    var dpr = Math.min(window.devicePixelRatio || 1, 2);
    var w = 0, h = 0, nodes = [], running = false, raf = 0;

    function accent() {
      return document.documentElement.getAttribute('data-theme') === 'dark'
        ? { r: 155, g: 155, b: 242 }
        : { r: 59, g: 59, b: 140 };
    }

    function resize() {
      var rect = canvas.parentElement.getBoundingClientRect();
      w = rect.width; h = rect.height;
      canvas.width = w * dpr; canvas.height = h * dpr;
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
      var count = Math.min(70, Math.floor(w * h / 26000));
      nodes = [];
      for (var i = 0; i < count; i++) {
        nodes.push({
          x: Math.random() * w,
          y: Math.random() * h,
          vx: (Math.random() - 0.5) * 0.22,
          vy: (Math.random() - 0.5) * 0.22
        });
      }
    }

    function tick() {
      if (!running) return;
      ctx.clearRect(0, 0, w, h);
      var c = accent();
      var i, j, a, b, dx, dy, d2;
      for (i = 0; i < nodes.length; i++) {
        a = nodes[i];
        // gentle sine drift — "flow", not bounce
        a.x += a.vx + Math.sin((a.y + performance.now() * 0.02) * 0.004) * 0.12;
        a.y += a.vy;
        if (a.x < -20) a.x = w + 20; else if (a.x > w + 20) a.x = -20;
        if (a.y < -20) a.y = h + 20; else if (a.y > h + 20) a.y = -20;
        ctx.beginPath();
        ctx.arc(a.x, a.y, 1.4, 0, Math.PI * 2);
        ctx.fillStyle = 'rgba(' + c.r + ',' + c.g + ',' + c.b + ',0.35)';
        ctx.fill();
      }
      for (i = 0; i < nodes.length; i++) {
        for (j = i + 1; j < nodes.length; j++) {
          a = nodes[i]; b = nodes[j];
          dx = a.x - b.x; dy = a.y - b.y; d2 = dx * dx + dy * dy;
          if (d2 < 110 * 110) {
            ctx.beginPath();
            ctx.moveTo(a.x, a.y);
            ctx.lineTo(b.x, b.y);
            ctx.strokeStyle = 'rgba(' + c.r + ',' + c.g + ',' + c.b + ',' +
              (0.12 * (1 - d2 / (110 * 110))).toFixed(3) + ')';
            ctx.lineWidth = 1;
            ctx.stroke();
          }
        }
      }
      raf = requestAnimationFrame(tick);
    }

    function setRunning(on) {
      if (on === running) return;
      running = on;
      if (on) raf = requestAnimationFrame(tick);
      else cancelAnimationFrame(raf);
    }

    resize();
    window.addEventListener('resize', resize);
    document.addEventListener('visibilitychange', function () {
      setRunning(!document.hidden && visible);
    });
    var visible = true;
    new IntersectionObserver(function (entries) {
      visible = entries[0].isIntersecting;
      setRunning(visible && !document.hidden);
    }).observe(canvas.parentElement);
    setRunning(true);
  }

  if (!reduced) startFlowField();

  /* ------------------------------------------------ GSAP motion */
  if (reduced || typeof gsap === 'undefined') return;
  if (typeof ScrollTrigger !== 'undefined') gsap.registerPlugin(ScrollTrigger);

  var EASE = 'power3.out';

  // Hero entrance — one timeline, compiler-pass pacing.
  var hero = gsap.timeline({ defaults: { ease: EASE } });
  hero
    .from('[data-hero="eyebrow"]', { y: 14, autoAlpha: 0, duration: 0.7 })
    .from('[data-hero="line"]', {
      yPercent: 115, duration: 1.0, stagger: 0.12
    }, '-=0.45')
    .from('[data-hero="fade"]', {
      y: 26, autoAlpha: 0, duration: 0.9, stagger: 0.14
    }, '-=0.55')
    // the narrowing: each bar enters wide, then narrows to its type
    .from('.hp-bar-row', { autoAlpha: 0, y: 14, duration: 0.5, stagger: 0.28 }, '-=0.6')
    .from('.hp-bar-2', { width: '100%', duration: 0.9, ease: 'power4.inOut' }, '-=0.7')
    .from('.hp-bar-3', { width: '100%', duration: 0.9, ease: 'power4.inOut' }, '-=0.55')
    .from('.hp-bar-caption', { autoAlpha: 0, duration: 0.6 }, '-=0.3');

  if (typeof ScrollTrigger === 'undefined') return;

  // Generic reveals.
  gsap.utils.toArray('[data-reveal]').forEach(function (el) {
    gsap.from(el, {
      y: 32, autoAlpha: 0, duration: 0.95, ease: EASE,
      scrollTrigger: { trigger: el, start: 'top 84%', once: true }
    });
  });

  // Grouped reveals — children stagger.
  gsap.utils.toArray('[data-reveal-group]').forEach(function (group) {
    gsap.from(group.children, {
      y: 24, autoAlpha: 0, duration: 0.8, ease: EASE, stagger: 0.08,
      scrollTrigger: { trigger: group, start: 'top 84%', once: true }
    });
  });

  // Service cards.
  gsap.utils.toArray('[data-stagger]').forEach(function (grid) {
    gsap.from(grid.children, {
      y: 44, autoAlpha: 0, duration: 0.9, ease: EASE, stagger: 0.12,
      scrollTrigger: { trigger: grid, start: 'top 82%', once: true }
    });
  });

  // Process — the rail draws as you scroll; steps pop in.
  var rail = document.querySelector('.hp-process-line');
  if (rail) {
    gsap.fromTo(rail, { scaleY: 0 }, {
      scaleY: 1, ease: 'none',
      scrollTrigger: {
        trigger: '.hp-process',
        start: 'top 75%', end: 'bottom 55%', scrub: 0.6
      }
    });
  }
  gsap.utils.toArray('[data-step]').forEach(function (step) {
    gsap.from(step, {
      x: -28, autoAlpha: 0, duration: 0.8, ease: EASE,
      scrollTrigger: { trigger: step, start: 'top 82%', once: true }
    });
  });

  // Case studies — copy reveals; the stat block drifts (parallax).
  gsap.utils.toArray('[data-case]').forEach(function (item) {
    gsap.from(item.querySelector('.hp-case-copy'), {
      y: 36, autoAlpha: 0, duration: 0.95, ease: EASE,
      scrollTrigger: { trigger: item, start: 'top 80%', once: true }
    });
    gsap.from(item.querySelector('.hp-case-visual'), {
      autoAlpha: 0, scale: 0.96, duration: 1.0, ease: EASE,
      scrollTrigger: { trigger: item, start: 'top 80%', once: true }
    });
    gsap.fromTo(item.querySelector('.hp-case-stat'), { y: 18 }, {
      y: -18, ease: 'none',
      scrollTrigger: { trigger: item, start: 'top bottom', end: 'bottom top', scrub: 0.8 }
    });
  });

  // Excellence layers — each layer draws in, narrowing as it goes.
  var layers = gsap.utils.toArray('[data-layer]');
  if (layers.length) {
    gsap.from(layers, {
      width: 0, autoAlpha: 0, duration: 0.85, ease: 'power4.inOut', stagger: 0.12,
      scrollTrigger: { trigger: '.hp-layers', start: 'top 78%', once: true }
    });
  }

  /* --------------------------------------------- Magnetic CTAs */
  if (window.matchMedia('(pointer: fine)').matches) {
    document.querySelectorAll('.hp-magnetic').forEach(function (btn) {
      var setX = gsap.quickTo(btn, 'x', { duration: 0.35, ease: 'power3.out' });
      var setY = gsap.quickTo(btn, 'y', { duration: 0.35, ease: 'power3.out' });
      btn.addEventListener('pointermove', function (e) {
        var r = btn.getBoundingClientRect();
        setX((e.clientX - (r.left + r.width / 2)) * 0.22);
        setY((e.clientY - (r.top + r.height / 2)) * 0.3);
      });
      btn.addEventListener('pointerleave', function () {
        gsap.to(btn, { x: 0, y: 0, duration: 0.6, ease: 'elastic.out(1, 0.45)' });
      });
    });
  }
})();
