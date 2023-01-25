Rails.configuration.x.image_optim = ImageOptim.new(
  nice: 20,
  allow_lossy: true,
  gifsicle: {
    level: 2,
    careful: true
  },
  optipng: {
    level: 5
  },
  jpegoptim: {
    max_quality: 80
  },
  jpegtran: false,
  jpegrecompress: false,
  oxipng: false,
  pngcrush: false,
  advpng: false,
  pngout: false,
  svgo: false,
  pngquant: false
)
