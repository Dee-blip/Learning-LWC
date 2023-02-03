/**
 * @description       : 
 * @author            : Vishnu Vardhan
 * @group             : 
 * @last modified on  : 02-22-2022
 * @last modified by  : Vishnu Vardhan
 * Modifications Log
 * Ver   Date         Author           Modification
 * 1.0   12-09-2021   Vishnu Vardhan   Initial Version
**/
import { LightningElement, api } from 'lwc';

export default class ScJarvisFlexibutton extends LightningElement {

    @api label;
    @api textColor;
    @api bgColor;
    @api bgHoverColor;
    @api borderColor;
    @api borderRadius;
    @api height;
    @api width;
    @api alignment;
    @api position; // normal, left, right
    @api margin;

    get buttonCss() {
        if(this.position === 'left') {
            return 'float-button left';
        } else if(this.position === 'right') {
            return 'float-button right';
        } 
        return 'button';
    }

    renderedCallback() {
        this.initCSSVariables();
    }


    initCSSVariables() {
        
        this.setCssProperty('--jvButtonWidth', this.width);
        this.setCssProperty('--jvButtonHeight', this.height);
        this.setCssProperty('--jvButtonMargin', this.margin);
        this.setCssProperty('--jvButtonBgColor', this.bgColor);
        this.setCssProperty('--jvButtonTextColor', this.textColor);
        this.setCssProperty('--jvButtonTextAlign', this.alignment);
        this.setCssProperty('--jvBorderRadius', this.borderRadius);
    }

    setCssProperty(cssPropName, cssValue) {
        if(cssValue) {
            const css = document.body.style;
            css.setProperty(cssPropName, cssValue)
        }
    }

    handleClick() {
        this.dispatchEvent(new CustomEvent('flexiclick'));
    }
}