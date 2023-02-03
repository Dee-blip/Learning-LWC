import { LightningElement, track } from 'lwc';
import getSearchResponse from '@salesforce/apex/SearchAkamaiCommunityResultPageCtrl.getSearchResponse';
import getUser from '@salesforce/apex/SearchAkamaiCommunityResultPageCtrl.getUser';
//import chatTexts1 from '@salesforce/label/c.Mkt_EC_Text1';

export default class SearchAkamaiBar extends LightningElement {
    @track searchText = "";
    firstrun = true;
    globalTimeout = null;
    @track error;
    @track auto_Complete = [];
    filters = [];
    @track showAutocompleteDIV = false;
    @track isCCProfile = false;
    @track loading_auto_complete = false;
    //@track chatText1 = JSON.parse(chatTexts1);
    @track searchString = "";
    user_name='';
    user_id='';
    user_Profile='';
    getUserLang = document.getElementsByTagName('html')[0].getAttribute("lang");
    keyword = window.location.pathname.includes('/global-search/') ? decodeURIComponent(window.location.pathname.split('/global-search/')[1]) : '';
    showMargin = window.location.pathname.includes('/global-search/') ? true : false;

    languageMap = {
        'en-US' : 'en',
        'zh-Hans-CN' : 'zs',
        'zh-Hant-TW' : 'zh',
        'ja' : 'ja',
        'ko' : 'ko',
        'fr' : 'fr',
        'pt-BR' : 'pt',
        'es' : 'es',
        'de' : 'de',
        'it' : 'it'
    }
    renderedCallback() {
        var query ='';
        if(this.firstrun){
            if(window.location.pathname.includes('global-search')) {
                query = decodeURIComponent(window.location.pathname.split('/global-search/')[1]);
                this.template.querySelector('[data-id="inputsearchbar"]').value = query;
            }
            this.getUserProfile();
            this.firstrun = false;
        }
        document.getElementById('search_bar_id').onclick = e => {
            this.searchText = this.template.querySelector('[data-id="inputsearchbar"]').value;
            if(this.searchText.trim().length >= 1){
                this.showAutocompleteDIV = true;
                this.loading_auto_complete = true;
                clearTimeout(this.timeoutId);
                this.timeoutId = setTimeout(this.getAutoCompleteResults.bind(this, this.searchText), 500);
            }
            else{
                // Do not show autocomplete div if search term length is 0
                this.showAutocompleteDIV = false;
            }

            e.stopPropagation();
          }
        window.addEventListener('click', e => {
            if (!document.getElementById('search_bar_id').contains(e.target)){
                this.showAutocompleteDIV = false;
            }
        })
        this.searchString =  this.template.querySelector('[data-id="inputsearchbar"]').value;
    }

    getAutoCompleteResults(search_term){
        let langValue;
        if(this.languageMap[this.getUserLang] !== undefined){
            langValue = this.languageMap[this.getUserLang];
        }
        else{
            langValue = 'en';
        }
        this.auto_Complete=[];
        let filter = {
            "method": "search.profile",
            "profile": "AutoComplete",
            "query": {
                "text": search_term.trim(),
                "skipFrom": 0,
                "sort": "globalrelevance.desc",
                "precision": "Default",
                "scmode": "Smart",
                //"questionLanguage" : "en",
                "additionalWhereClause": "((treepath = '/Akamai.com/' and (documentlanguages='"+langValue+"' or documentlanguages='en')) or (treepath <> '/Akamai.com/'))",
                "selections": []
            },
            "responseType": "SearchResult",
            "tabSearchValue": "/*"
        }
        getSearchResponse({ body : JSON.stringify(filter), apiName : 'results'})
        .then(data => {
            let responseResult = JSON.parse(data);
            let autoResponse=[];
            this.error = undefined;
            this.loading_auto_complete = false;
            if(responseResult.DocumentCount > 0 && responseResult.Result.Docs.length > 0) {

                this.auto_results = responseResult.Result.Docs;

                for(let i=0; i<this.auto_results.length; i++) {
                    if(this.auto_results[i].sourcestr37 !== 'QuestionPost'){
                        if(this.auto_results[i].sourcestr36 === 'User')
                            this.auto_results[i].title = 'Post - ' + this.auto_results[i].sourcestr35;
                        else if(this.auto_results[i].sourcestr36 === 'CollaborationGroup')
                            this.auto_results[i].title = 'Post in ' + this.auto_results[i].sourcestr35;
                    }
                    if(this.auto_results[i].Akamai_Source === 'Akamai Website'){
                        this.auto_results[i].Akamai_Source = this.auto_results[i].Akamai_Source + ' (' + this.auto_results[i].languages.toUpperCase() + ')';
                    }
                    autoResponse.push({
                        'Id':this.auto_results[i].docid,
                        'title': this.auto_results[i].title,
                        'documenturl': this.auto_results[i].url1,
                        'Akamai_Source': this.auto_results[i].Akamai_Source,
                        'Content_Type': this.auto_results[i].Content_Type,
                        //'modified': (this.auto_results[i].Akamai_Source == 'Akamai Community' || this.auto_results[i].Akamai_Source == 'Knowledge Articles') ? this.auto_results[i].modified.substring(0, 10) : '',
                        'languages': this.auto_results[i].languages,
                        'hasBestAnswer': this.auto_results[i].sourcestr38 !== undefined ? true : false,
                        'commentCount': this.auto_results[i].sourceint2,
                        'likeCount': this.auto_results[i].sourceint3,
                        'viewCount': this.auto_results[i].sourceint4,
                        'articleNumber': this.auto_results[i].sourcestr7
                    });
                }
                this.auto_Complete = autoResponse;
            }
            else{
                this.auto_Complete = [];
            }
        })
        .catch(error => {
            console.log('error:: '+error);
            this.error = error;
        });
    }

    handleChange(evt) {
        var isEnterKey;
        evt.preventDefault();
        this.searchText = this.template.querySelector('[data-id="inputsearchbar"]').value;
        isEnterKey = evt.keyCode === 13;
        this.searchString =  this.searchText;
        if (isEnterKey) {
            if(encodeURIComponent(this.searchText.trim()).length !== 0){
            this.search(encodeURIComponent(this.searchText.trim()));
            }
        }
        else {
            if(this.searchText.trim().length >= 1){
                this.loading_auto_complete = true;
                this.showAutocompleteDIV = true;
                clearTimeout(this.timeoutId);
                this.timeoutId = setTimeout(this.getAutoCompleteResults.bind(this, evt.target.value), 500);
            }
            else{
                this.auto_Complete = [];
                this.loading_auto_complete = false;
                this.showAutocompleteDIV = false;
            }
        }
    }

    updateinputsearch(evt){
        this.captureAudit(this.template.querySelector('[data-id="inputsearchbar"]').value.trim(), 'click.autoCompleteResult', evt.currentTarget.dataset.value);
        //window.location = evt.currentTarget.dataset.url;
        window.open(evt.currentTarget.dataset.url,'_blank');
    }

    handleClickSearch(e) {
        e.stopPropagation();
        if(encodeURIComponent(this.template.querySelector('[data-id="inputsearchbar"]').value.trim()).length !== 0){
            this.search(encodeURIComponent(this.template.querySelector('[data-id="inputsearchbar"]').value.trim()));
            //eval("$A.get('e.force:refreshView').fire();");
        }
    }

    search(term) {
        var e;
        this.template.querySelector('[data-id="inputsearchbar"]').value = decodeURIComponent(term);
        this.showAutocompleteDIV = false;
        let url = window.location.origin+'/customers/s/global-search/' + term;
        if(window.location.pathname.includes('customers/s/global-search')) {
            //window.history.pushState({ path: url }, '', url);
            try{
                window.history.pushState({}, '','/customers/s/global-search/ '+term);
            }
            catch(error){
                console.log(error);
                this.error = error;
            }
            e = new Event('replaceState');
            e.arguments = arguments;
            window.dispatchEvent(e);
        } else  {
            window.location = url;
        }
    }

    getUserProfile(){
        getUser()
        .then(data => {
            this.user_Profile = JSON.parse(data).profileName;
            this.user_id = JSON.parse(data).Id;
            this.user_name = JSON.parse(data).userName;
            if(JSON.parse(data).profileName==="Customer Community Profile")
                this.isCCProfile=true;
            this.isAuditCapturedAtPageLoad = true;
        })
    }

    redirectToLogin(){
        var keyword = this.searchText;
        window.location = window.location.origin+'/customers/s/login/?searchQuery=' + encodeURIComponent(keyword);
    }

    redirectToMyFeed(){
        window.location = window.location.origin+'/customers/s/my-feed';
    }

    captureAudit(search_term, action, item){
        if(search_term.trim().length>=1){
            let filter = {
                "method" : "dev.plugin",
                "plugin" : "insert_audit",
                "searchterm" : search_term.trim(),
                "action" : action,
                "userName" : this.user_name,
                "userId" : this.user_id,
                "userProfile" : this.user_Profile,
                "hostname" : window.location.hostname,
                "resultcount" : 0,
                "item" : item,
                "rank" : 0,
                "source" : ''
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
}