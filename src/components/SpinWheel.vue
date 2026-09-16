<template>
  <div
    id="group-dropdown"
    class="z-1 w-full flex justify-content-center align-items-center text-center text-base sm:text-3xl md:text-5xl font-bold"
  >
    {{ GroupLabel }}
  </div>
  <div ref="container" class="flex spin-container">
    <div class="pointer-container">
      <img :src="'./img/base_flicker.png'" class="base-flicker" alt="Base Flicker" />
      <img
        :src="'./img/flicker.png'"
        class="flicker"
        :style="{ transform: `rotate(${pointerRotation}deg)` }"
        alt="Flicker"
      />
    </div>

    <div
      class="icon"
      @click="spin"
      @keyup.enter="spin"
      @keyup.space="spin"
      v-tooltip.bottom="{
        value: `↻ Spin!`,
        class: 'text-xl',
        escape: true
      }"
      tabindex="0"
    ></div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, watch } from 'vue';
import random from 'random';
import { Wheel, type WheelProps } from 'spin-wheel';
import { useDialog } from 'primevue/usedialog';
import { TickSound, LabelLength } from '@/services/SettingService';
import { GroupLabel, Items } from '@/services/ItemService';
import CongratulationDialog from '@/components/CongratulationDialog.vue';

const patternImg = new Image();
patternImg.src = './img/pattern.jpeg';
patternImg.onload = () => wheel?.refresh();

const properties: WheelProps = {
  // debug: import.meta.env.DEV,
  isInteractive: false,
  radius: 0.48,
  rotationResistance: 0,
  itemLabelRadius: 0.92,
  itemLabelRadiusMax: 0.3,
  itemLabelRotation: 180,
  itemLabelAlign: 'left',
  itemLabelColors: ['#333'],
  itemLabelBaselineOffset: -0.07,
  // Should also change app.scss
  itemLabelFont:
    '"Suez One", "Mochiy Pop P One", "Jua", "Unbounded", "Mitr", "Noto Sans TC", "Noto Sans SC", "Noto Sans Lao", "Noto Color Emoji"',
  itemLabelFontSizeMax: 55,
  itemBackgroundColors: [
  ],
  rotationSpeedMax: 2000,
  lineWidth: 1,
  lineColor: '#000',
  items: []
};

const container = ref();

let spinCount = 0;
let wheel: Wheel | undefined = undefined;

const pointerRotation = ref(0);
let pointerAngle = 0;
let pointerVelocity = 0;
let lastRotation = 0;
let pointerRaf: number | null = null;

const updatePointer = () => {
  if (!wheel) {
    pointerRaf = requestAnimationFrame(updatePointer);
    return;
  }
  
  const currentRotation = wheel.rotation;
  let delta = currentRotation - lastRotation;
  
  if (delta > 180) delta -= 360;
  if (delta < -180) delta += 360;
  
  lastRotation = currentRotation;
  
  let pushAngle = 0;
  const angles = wheel.getItemAngles(currentRotation);
  for (const a of angles) {
    let pinAngle = a.start % 360;
    if (pinAngle < 0) pinAngle += 360;
    
    if (delta >= 0) {
      if (pinAngle > 352 && pinAngle <= 360) {
        pushAngle = -((pinAngle - 352) / 8) * 20;
      }
    } else {
      if (pinAngle >= 0 && pinAngle < 8) {
        pushAngle = ((8 - pinAngle) / 8) * 20;
      }
    }
  }
  
  if (delta >= 0) {
    if (pushAngle < pointerAngle) {
      pointerAngle = pushAngle;
      pointerVelocity = 0;
    }
  } else {
    if (pushAngle > pointerAngle) {
      pointerAngle = pushAngle;
      pointerVelocity = 0;
    }
  }
  
  const k = 0.3; // Spring constant
  const c = 0.2; // Damping
  const force = -k * pointerAngle - c * pointerVelocity;
  pointerVelocity += force;
  pointerAngle += pointerVelocity;
  
  pointerRotation.value = pointerAngle;
  
  pointerRaf = requestAnimationFrame(updatePointer);
};

const stopAndClearSound = () => {
  if (!wheel) return;

  wheel.stop();
};

const playSound = () => {
  if (!TickSound.value) return;

  const src = TickSound.value.value.startsWith('data:')
    ? TickSound.value.value
    : `./sound/${TickSound.value.value}`;
  const audio = new Audio(src);
  audio.volume = 0.3;
  audio.play();
};

const spin = () => {
  if (!wheel) return;

  wheel.rotationResistance = -400;
  wheel.spin(wheel.rotationSpeed + random.int(1000, 1600));
};

const dialog = useDialog();
const openCongratulationDialog = ($event: {
  type: 'rest';
  currentIndex: number;
  rotation: number;
}) => {
  dialog.open(CongratulationDialog, {
    props: {
      modal: true,
      showHeader: false,
      // The winner is announced over the mask, with no dialog chrome behind it.
      // PrimeVue 3 painted the surface on the content, which is why the old
      // `contentStyle` was enough; from v4 on the root carries it instead.
      style: 'border: 0; background: transparent; box-shadow: none',
      dismissableMask: true
    },
    data: {
      item: Items.value![$event.currentIndex]
    }
  });
};

const dowelImg = new Image();
dowelImg.src = './img/wooden_dowel.png';

const updatePinsImage = () => {
  if (!wheel || !Items.value?.length) return;
  const angles = wheel.getItemAngles(0);
  
  const drawPins = () => {
    const canvas = document.createElement('canvas');
    canvas.width = 500;
    canvas.height = 500;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;
    
    const radius = 242; 
    const size = 16;
    const offset = size / 2;

    ctx.shadowColor = 'rgba(0,0,0,0.5)';
    ctx.shadowBlur = 4;
    ctx.shadowOffsetX = 1;
    ctx.shadowOffsetY = 2;
    
    for (const a of angles) {
      const rad = (a.start - 90) * Math.PI / 180;
      const cx = 250 + Math.cos(rad) * radius;
      const cy = 250 + Math.sin(rad) * radius;
      ctx.drawImage(dowelImg, cx - offset, cy - offset, size, size);
    }
    
    const img = new Image();
    img.src = canvas.toDataURL();
    img.onload = () => {
      if (wheel) wheel.image = img;
    };
  };

  if (dowelImg.complete && dowelImg.naturalHeight !== 0) {
    drawPins();
  } else {
    dowelImg.addEventListener('load', drawPins, { once: true });
  }
};

onMounted(() => {
  watch(
    Items,
    (newValue) => {
      wheel!.items = (newValue || []).map((i) => ({
        ...i,
        image: patternImg,
        imageScale: 0.2
      }));
      updatePinsImage();
    },
    { deep: true }
  );

  watch(LabelLength, (newValue) => {
    wheel!.itemLabelRadiusMax = 1 - newValue;
  });

  wheel = new Wheel(container.value, {
    ...properties,
    items: Items.value?.map((i) => ({ ...i, image: patternImg, imageScale: 0.2 })) || [],
    itemLabelRadiusMax: 1 - LabelLength.value
  });

  updatePinsImage();

  // Setup wheel ticks and high-speed pointer kicks globally, rather than just in `spin()`
  // (this means dragging the wheel also correctly bounces the pointer and ticks).
  wheel.onCurrentIndexChange = () => {
    if (!wheel) return;
    playSound();

    const delta = wheel.rotation - lastRotation;
    if (wheel.rotationSpeed > 50 || delta > 2) {
       pointerAngle = -20;
       pointerVelocity = 0;
    } else if (wheel.rotationSpeed < -50 || delta < -2) {
       pointerAngle = 20;
       pointerVelocity = 0;
    }

    switch (true) {
      case Math.abs(wheel.rotationSpeed) < 30:
        wheel.rotationResistance = -10;
        break;
      case Math.abs(wheel.rotationSpeed) < 100:
        wheel.rotationResistance = -30;
        break;
      case Math.abs(wheel.rotationSpeed) < 400:
        wheel.rotationResistance = -100;
        break;
    }
  };

  wheel.onRest = ($event) => {
    stopAndClearSound();
    openCongratulationDialog($event);
  };

  wheel.onSpin = () => {
    gtag('event', 'spin');
    gtag('event', 'spin_count', {
      count: ++spinCount
    });
  };

  // Workaround for itemLabelRadiusMax not working on first load.
  setTimeout(() => {
    wheel!.itemLabelRadiusMax = 1 - LabelLength.value;
  }, 50);

  pointerRaf = requestAnimationFrame(updatePointer);
});

onUnmounted(() => {
  if (pointerRaf !== null) cancelAnimationFrame(pointerRaf);
});
</script>

<style lang="scss" scoped>
@use 'primeflex/core/_variables.scss' as v;
@use 'sass:map' as map;

#group-dropdown {
margin-top: 0vh;
margin-bottom:1vh;
}

.spin-container {
  flex-shrink: 0;
  aspect-ratio: 1/1;
  width: 130vh;
  height: 130vh;

  margin-top: -12vh;
  position: relative;
  z-index: 2;

  @media (min-width: map.get(v.$breakpoints, 'sm')) {
    width: 140vh;
    height: 140vh;
    margin-top: -28vh;
  }

  @media (min-width: map.get(v.$breakpoints, 'md')) {
    width: 150vh;
    height: 150vh;
    margin-top: -33vh;
  }
}

:deep(canvas) {
  position: relative;
  z-index: 1;
}

.pointer-container {
  $icon-size: 10vh;
  width: $icon-size;
  height: $icon-size;
  position: absolute;
  top: calc(25% - 5vh);
  left: calc(50% - 5vh);

 .base-flicker,
  .flicker {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    object-fit: contain;
  }

  .base-flicker {
    z-index: 0;
  }

  .flicker {
    z-index: 11;
    transform-origin: 50% 30%;
    filter: drop-shadow(0px 2px 4px rgba(0,0,0,0.5));
  }
}

.button-container {
  margin-top: -5.5rem;

  button {
    z-index: 2;
    position: relative;

    $background-color: #0c0f1d;
    background: $background-color;

    &:hover {
      filter: brightness(1.3);
    }
  }
}

.icon {
  $icon-size: 13vh;
  cursor: pointer;

  width: $icon-size;
  height: $icon-size;
  border-radius: 50%;

  background-image: url(../img/icon.png);
  background-image: -webkit-image-set(
    url(../img/icon.avif) type('image/avif'),
    url(../img/icon.webp) type('image/webp'),
    url(../img/icon.png) type('image/png')
  );
  background-image: image-set(
    url(../img/icon.avif) type('image/avif'),
    url(../img/icon.webp) type('image/webp'),
    url(../img/icon.png) type('image/png')
  );

  background-size: contain;
  background-position: center;
  background-repeat: no-repeat;
  transform: translateZ(0);

  position: absolute;
  top: calc(calc(50%) - calc($icon-size / 2));
  left: calc(calc(50%) - calc($icon-size / 2));
  z-index: 10;

  &:hover {
    filter: brightness(1.1);
  }
}
</style>
