import { LightningElement, api } from 'lwc';

export default class ScSTMCellEdit extends LightningElement {
    @api context;
    @api supportTeamSkill;
    @api firstName;
    @api lastName;
    @api login;
    @api team;
    
    get isLogin(){
        return this.login == undefined ? false : true;
    }

    get isSkill(){
        console.log(this.supportTeamSkill);
        return (this.login == undefined && this.team == undefined) ? true : false;
    }

    get isTeam(){
        return this.team == undefined ? false : true;
    }

    handleEdit() {
        this.dispatchEvent(new CustomEvent('editskill', {
            composed: true,
            bubbles: true,
            cancelable: true,
            detail: {
                data: { recordId: this.context, SupportTeamSkill: this.supportTeamSkill, FirstName: this.firstName, LastName: this.lastName }
            }
        }));
      }

    handleDetails() {
        this.dispatchEvent(new CustomEvent('showteamdetail', {
            composed: true,
            bubbles: true,
            cancelable: true,
            detail: {
                data: { recordId: this.context, FirstName: this.firstName, LastName: this.lastName }
            }
        }));
      }

    handleAccountDetails() {
        this.dispatchEvent(new CustomEvent('showaccountdetail', {
            composed: true,
            bubbles: true,
            cancelable: true,
            detail: {
                data: { recordId: this.context, TeamName: this.team }
            }
        }));
      }
}