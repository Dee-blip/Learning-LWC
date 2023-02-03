import { LightningElement, track } from 'lwc';
import getCaseList from '@salesforce/apex/customCaseSearchController.getCaseList';
import getCommunityCommentsList from '@salesforce/apex/customCaseSearchController.getCommunityCommentsList';
import getSearchResponse from '@salesforce/apex/SearchAkamaiCommunityResultPageCtrl.getSearchResponse';
import getUser from '@salesforce/apex/SearchAkamaiCommunityResultPageCtrl.getUser';
//import getCaseCommentsList from '@salesforce/apex/customCaseSearchController.getCaseCommentsList';

export default class ApexWireMethodToProperty extends LightningElement {
    @track error = null;
    @track pageSize = 10;
    @track pageSizeComments = 10;
    @track pageNumber = 1;
    @track pageNumberComments = 1;
    @track totalRecords = 0;
    @track totalRecordsComments = 0;
    @track totalPages = 0;
    @track totalPagesComments = 0;
    @track recordEnd = 0;
    @track recordEndComments = 0;
    @track recordStart = 0;
    @track recordStartComments = 0;
    @track isPrev = true;
    @track isPrevComments = true;
    @track isNext = true;
    @track isNextComments = true;
    @track cases = [];
    @track communityComments = [];
    @track showCasesWhenListIsNotEmpty = true;
    @track showCommentsWhenListIsNotEmpty = true;
    @track showcaselist = true;
    @track showcommentlist = true;
    @track searchCaseText = window.location.pathname.includes('/global-search/') ? decodeURIComponent(window.location.pathname.split('/global-search/')[1]) : '';
    @track userdetails = {};
    initialRun = false;
    //@wire(getCaseCommentsList, { searchText: '$searchCaseText' }) casecomments;
    
    connectedCallback() {
        window.addEventListener('triggerforCase', () => {
            this.handleMessage();
        }); 
        window.addEventListener('replaceState', () => {
            this.handleMessage();
        }); 
        if(! this.initialRun) {
            this.initialRun = true;
            this.getDetails();
        }
       this.getCases();
       this.getCaseComment();
    }  

    handleMessage(){
        this.searchCaseText = window.location.pathname.includes('/global-search/') ? decodeURIComponent(window.location.pathname.split('/global-search/')[1]) : '';
        this.pageNumber =1;
        this.pageNumberComments =1;
        this.getCases();
        this.getCaseComment();
    }

    // get user info for CASE
    getDetails() {
        getUser()
            .then(data => {
                try {
                    this.userdetails.userProfile = JSON.parse(data).profileName;
                    this.userdetails.userid = JSON.parse(data).Id;
                    this.userdetails.username = JSON.parse(data).userName;
                } catch(error) {
                    console.log(error.message);
                    this.error = error.message;
                }
            })
            .catch(error => {
                console.log(error);
                this.error = error;
            });
    }

    gettesting(event){
        var urlValue = window.location.origin;
        var casesid = event.target.dataset.id;
        urlValue = urlValue+"/customers/s/case/"+casesid;
        window.open(urlValue);
        this.captureCaseAudit(this.searchCaseText.trim(),'click.caseresultlink',this.totalRecords,event.target.dataset.title,event.target.dataset.akamid,'Cases',event.target.dataset.rank);
    }

    redirectoncase(event){
        var urlValue1 = window.location.origin;
        var casesid1 = event.currentTarget.dataset.id;
        urlValue1 = urlValue1+"/customers/s/case/"+casesid1;
        urlValue1 = urlValue1+"/"+casesid1;
        window.open(urlValue1);
        this.captureCaseAudit(this.searchCaseText.trim(),'click.casecommentresultlink',this.totalRecordsComments,event.currentTarget.dataset.cctitle,event.currentTarget.dataset.ccakamid,'Case Comments',event.currentTarget.dataset.ccrank);
    }

    workdropdown(){
        if(this.showcaselist){
            this.showcaselist = false;
        }else{
            this.showcaselist = true;
        }
    }

    workdropdowncomments(){
        if(this.showcommentlist){
            this.showcommentlist = false;
        }else{
            this.showcommentlist = true;
        }
    }

    //handle next
    handleNext(){
        this.pageNumber = this.pageNumber+1;
        this.getCases();
        this.captureCaseAudit(this.searchCaseText.trim(),'click.casepage'+(this.pageNumber),this.totalRecords,"","","","");
    }
 
    //handle prev
    handlePrev(){
        this.pageNumber = this.pageNumber-1;
        this.getCases();
        this.captureCaseAudit(this.searchCaseText.trim(),'click.casepage'+(this.pageNumber),this.totalRecords,"","","","");
    }

    handleNextClick(){
        this.pageNumberComments = this.pageNumberComments+1;
        this.getCaseComment();
        this.captureCaseAudit(this.searchCaseText.trim(),'click.casecommentpage'+(this.pageNumberComments),this.totalRecords,"","","","");
    }

    handlePreviousClick(){
        this.pageNumberComments = this.pageNumberComments-1;
        this.getCaseComment();
        this.captureCaseAudit(this.searchCaseText.trim(),'click.casecommentpage'+(this.pageNumberComments),this.totalRecords,"","","","");
    }

    //get cases
    getCases(){
        var resultData;
        this.searchCaseText = window.location.pathname.includes('/global-search/') ? decodeURIComponent(window.location.pathname.split('/global-search/')[1]) : '';
        getCaseList({pageSize: this.pageSize, pageNumber : this.pageNumber, searchText: this.searchCaseText})
        .then(result => {
            if(result){
                resultData = JSON.parse(result);
                this.cases = resultData.cases;
                this.pageNumber = resultData.pageNumber;
                this.totalRecords = resultData.totalRecords;
                this.recordStart = resultData.recordStart;
                this.recordEnd = resultData.recordEnd;
                this.totalPages = Math.ceil(resultData.totalRecords / this.pageSize);
                this.isNext = (this.pageNumber === this.totalPages || this.totalPages === 0);
                this.isPrev = (this.pageNumber === 1 || this.totalRecords < this.pageSize);
                for(let i=0; i<this.cases.length;i++){
                    this.cases[i].caserank = (this.pageNumber - 1) * this.pageSize + (i+1);
                }
            }
        })
        .catch(error => {
            this.error = error;
        })
    }

    //get case comments
    getCaseComment(){
        var resultData1;
        this.searchCaseText = window.location.pathname.includes('/global-search/') ? decodeURIComponent(window.location.pathname.split('/global-search/')[1]) : '';
        getCommunityCommentsList({pageSizeComments: this.pageSizeComments, pageNumberComments : this.pageNumberComments, searchText: this.searchCaseText})
        .then(result1 => {
            if(result1){
                resultData1 = JSON.parse(result1);
                this.communityComments = resultData1.comments;
                this.pageNumberComments = resultData1.pageNumberComments;
                this.totalRecordsComments = resultData1.totalRecordsComments;
                this.recordStartComments = resultData1.recordStartComments;
                this.recordEndComments = resultData1.recordEndComments;
                this.totalPagesComments = Math.ceil(resultData1.totalRecordsComments / this.pageSizeComments);
                this.isNextComments = (this.pageNumberComments === this.totalPagesComments || this.totalPagesComments === 0);
                this.isPrevComments = (this.pageNumberComments === 1 || this.totalRecordsComments < this.pageSizeComments);
                if(this.communityComments.length === 0){
                    this.showCommentsWhenListIsNotEmpty = false;
                }
                for(let i = 0; i < this.communityComments.length; i++){
                    this.communityComments[i].ccrank = (this.pageNumberComments - 1) * this.pageSizeComments + (i+1);
                }
            }
        })
        .catch(error => {
            this.error = error;
        })
    }

    // Function to capture cases audit
    captureCaseAudit(search_term, action, resultCount, caseTitle, caseId,source, caseRank){
        let filter = {
            "method" : "dev.plugin",
            "plugin" : "insert_audit",
            "searchterm" : search_term.trim(),
            "action" : action,
            "userName" : this.userdetails.username,
            "userId" : this.userdetails.userid,
            "userProfile" : this.userdetails.userProfile,
            "hostname" : window.location.hostname,
            "resultcount" : resultCount,
            "item" : caseTitle,
            "rank" : caseRank,
            "source" : source,
            "docId" : caseId
        }
        getSearchResponse({ body : JSON.stringify(filter), apiName : 'audit'})
        .then(data => {
            if(JSON.parse(data).Status !== 'ok')
            {
                console.log('Something went wrong.');
            }
        })
        .catch(() => {
            console.log('Something went wrong!!!');
        });
    }
}