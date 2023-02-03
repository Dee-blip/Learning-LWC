import { LightningElement, api, track } from 'lwc';

const coordinates = {
    red: { cx: 150, cy: 100, r: 70 },
    yellow: { cx: 240, cy: 100, r: 70 },
    green: { cx: 330, cy: 100, r: 70 }

}

const radius = 50;
const highlightRadius = 80;
const overlap = 30;
const startX = 0;
const startY = 100;

export default class DdTrendIcons extends LightningElement {

    @api color;
    @api label;

    // Calculating the size and coordinates of icons
    get svgIconMeta() {

        let iconMeta = [];
        let cx = startX;
        let cy = startY;

        let color  = this.color ? this.color.toLowerCase(): '';

        ['green', 'red', 'yellow'].forEach((el) => {
            if (color === el) {

                cx = cx + highlightRadius;

                iconMeta.push({
                    color: el,
                    class: el,
                    radius: highlightRadius,
                    cx: cx,
                    cy: cy,
                    highlight: true,
                    label: this.label
                });
                cx = cx + highlightRadius - overlap;
            }
            else {
                cx = cx + radius;
                iconMeta.push({
                    color: el,
                    class: el + ' blur',
                    radius: radius,
                    cx: cx,
                    cy: cy
                });
                cx = cx + radius - overlap;

            }
        });

        return iconMeta.sort(this.compareIcons);
    }

    compareIcons = (a, b) => {
        if(a.highlight && !b.highlight) {
            return 1;
        }
        else if(!a.highlight && b.highlight){
            return -1;
        }
        return 0;
    }
}