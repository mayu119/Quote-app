import React from 'react';
import {AbsoluteFill, Composition, Img, staticFile, useCurrentFrame} from 'remotion';
import {registerRoot} from 'remotion';

const SLIDES = Array.from({length: 9}, (_, index) => `slides-solid-gray/${String(index + 1).padStart(2, '0')}.png`);
const FPS = 30;
const HOLD_FRAMES = 120; // 4.0 seconds per slide
const SLIDE_FRAMES = 24; // 0.8 seconds for a simple horizontal slide
const TOTAL_FRAMES = HOLD_FRAMES * SLIDES.length + SLIDE_FRAMES * (SLIDES.length - 1);

const Page = ({src, style = {}}) => (
  <Img
    src={staticFile(src)}
    style={{
      position: 'absolute',
      inset: 0,
      width: '100%',
      height: '100%',
      objectFit: 'cover',
      display: 'block',
      ...style,
    }}
  />
);

const HorizontalSlideVideo = () => {
  const frame = useCurrentFrame();
  const block = HOLD_FRAMES + SLIDE_FRAMES;
  const index = Math.min(Math.floor(frame / block), SLIDES.length - 1);
  const local = frame - index * block;
  const inSlide = index < SLIDES.length - 1 && local >= HOLD_FRAMES;
  const progress = inSlide ? (local - HOLD_FRAMES) / SLIDE_FRAMES : 0;
  const currentX = inSlide ? -progress * 100 : 0;
  const nextX = inSlide ? 100 - progress * 100 : 100;

  return (
    <AbsoluteFill style={{backgroundColor: '#6c6c6c', overflow: 'hidden'}}>
      <Page src={SLIDES[index]} style={{transform: `translateX(${currentX}%)`}} />
      {inSlide && (
        <Page src={SLIDES[index + 1]} style={{transform: `translateX(${nextX}%)`}} />
      )}
    </AbsoluteFill>
  );
};

const Root = () => (
  <Composition
    id="KodomoSodatteWakattaHorizontalSlide"
    component={HorizontalSlideVideo}
    durationInFrames={TOTAL_FRAMES}
    fps={FPS}
    width={1080}
    height={1920}
    defaultProps={{}}
  />
);

registerRoot(Root);
