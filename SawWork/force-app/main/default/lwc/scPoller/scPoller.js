import { LightningElement, api,  track } from 'lwc';

export default class Poller extends LightningElement {

    @track pollId;
    @api interval; // Polling interval
    @api smartpoll = false; // Pauses polling when user switch to another tab
   
    _disable;
    @api get disable(){
        return this._disable;
    }
    set  disable(val) {
        this._disable = val;
        const disablePoll = val && this.pollId;
        if(disablePoll) {
            window.clearInterval(this.pollId);
        } else if(!this.pollId){
            this.startPolling();
        }
    }

    connectedCallback() {
        if(this.smartpoll) {
            window.addEventListener("visibilitychange", this.handleVisibilityChange.bind(this));
        }
        if(!this.pollId && !this.disable) {
            this._disable = false;
            this.startPolling();
        }
    }

    handleVisibilityChange() {
        if (document.hidden || document.webkitHidden || document.msHidden || document.mozHidden) {
            window.clearInterval(this.pollId);
            this.pollId = '';
         }
        else {
            window.clearInterval(this.pollId);
            // this.dispatchEvent(new CustomEvent('poll'));
            this.startPolling();
        }
    }

    startPolling() {
        this.dispatchEvent(new CustomEvent('poll'));
        this.pollId = setInterval(() => {
            this.dispatchEvent(new CustomEvent('poll'));
        }, this.interval);
    }
}