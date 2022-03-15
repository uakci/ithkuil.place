const colorRoots = ["gy", "ňr", "ml", "čw", "ḑr", "lw", "žl", "vm"],
           stems = ["a" ,"e", "u"],
       grayscale = ["axm-", "ucv-", "acv-", "ecv-", "abv-"];

const colorStems = colorRoots.map(
  (root) => stems.map(
    (stem) => stem + root + "-"
)).reduce((curr, acc) => [...curr, ...acc], []);

console.log(colorStems);

const hueToRoot = (num) => colorStems[(Math.ceil(num / 15) + 1) % 24];

function hslToRoot({h, s, l}) {
  if(s < 0.2) {
      return grayscale[Math.floor(4.999 * l)];
  } else {
    return hueToRoot(h);
  }
}

// returns an array of base10 ints
const hexToRGB = (hex) => [
  hex.slice(1, 3),
  hex.slice(3, 5),
  hex.slice(5, 7)
].map((str) => parseInt(str, 16) / 255);

function hexStringToHSL (str) {
  const rgb = hexToRGB(str);
  console.log(rgb);
  const min = Math.min(...rgb);
  const max = Math.max(...rgb);
  let l = (min + max)/2;
  let s, h;
  if (max - min < 0.05) {
    s = 0;
    h = 0;
  } else {
    s = l < 0.5 ? (max - min) / (max + min)
                : (max - min) / (2.0 - max - min);
    const [red, green, blue] = rgb;
    if (red === max) {
      h = 0.0 + (green - blue) / (max - min);
    } else if (green === max) {
      h = 2.0 + (blue - red)   / (max - min);
    } else {
      // blue is max
      h = 4.0 + (red - green)  / (max - min);
    }
  };
  return {h: (h <= 0) * 360 + 60 * h,
          s, l};
};


function handleColorInput(event) {
  const value = event.target.value;
  const hsl = hexStringToHSL(value);
  const output = document.querySelector("output");
  output.value = hslToRoot(hsl);
  console.log(hsl);

  const body = document.body;
  body.style.setProperty("--page", value);

  console.log(value);
}

function setup() {
  const input = document.getElementById("color-picker");
  input.addEventListener("input", handleColorInput);
  handleColorInput({target: input});
}

window.addEventListener("load", setup);
