import { LightningElement, track } from 'lwc';
import getSearchResponse from '@salesforce/apex/SearchAkamaiCommunityResultPageCtrl.getSearchResponse';
import getUser from '@salesforce/apex/SearchAkamaiCommunityResultPageCtrl.getUser';

export default class SearchAkamaiCommunityResults extends LightningElement {
    @track results = [];
    @track error;
    keyword = window.location.pathname.includes('/global-search/') ? decodeURIComponent(window.location.pathname.split('/global-search/')[1]) : '';
    getUserLang = document.getElementsByTagName('html')[0].getAttribute("lang");
    @track count = 0;
    @track productsBox = [];
    @track solutionBox = [];
    @track contentType = [];
    @track sourceType = [];
    @track selectedSource = [];
    @track selectedContentTypes = [];
    @track selectedSolutions = [];
    @track selectedProducts = [];
    @track disablePrev = true;
    @track disableNext = true;
    @track isLoaded = false;
    @track showpopup = false;
    @track sortOptions = [{label: 'Title', value: 'title.asc', checked: false, show: true},
                          {label: 'Date', value: 'modified.desc', checked: false, show: false},
                          {label: 'Relevance', value: 'globalrelevance.desc', checked: true, show: true}];

    @track precisionOptions = [{label: 'Exact Expression', value: 'exactexpression', checked: false},
                                {label: 'Same Phrase', value: 'inthesamephrase', checked: false},
                                {label: 'Every Word', value: 'everyword', checked: false},
                                {label: 'Default', value: 'Default', checked: true}];
    
    // @track languageOptions = [  {label: 'English', key: 'en-US', value: 'en', checked: true},
    //                             {label: 'Chinese (Simplified)', key: 'zh-Hans-CN', value: 'zs', checked: false},
    //                             {label: 'Chinese (Traditional)', key: 'zh-Hant-TW', value: 'zh', checked: false},
    //                             {label: 'Japanese', key: 'ja', value: 'ja', checked: false},
    //                             {label: 'Korean', key: 'ko', value: 'ko', checked: false},
    //                             {label: 'French', key: 'fr', value: 'fr', checked: false},
    //                             {label: 'Portugese', key: 'pt-BR', value: 'pt', checked: false},
    //                             {label: 'Spanish', key: 'es', value: 'es', checked: false},
    //                             {label: 'German', key: 'de', value: 'de', checked: false},
    //                             {label: 'Italian', key: 'it', value: 'it', checked: false}
    //                         ];

    //@api authenticatedUser = false;
    @track selectedSortOption;
    @track precision;
    @track spellCheck;
    @track queryIntentResult;
    @track showQueryIntent = false;
    @track sponsoredLinks;
    @track allPage = true;
    @track invalidsearch = false;
    @track noresultfound = false;
    @track userdetails = {};

    filters = [];  
    firstRun = false;
    pageCount = 0; 
    currentPage = 0; 
    documentsPerPage = 20;
    skip = 0;    
    documentsThisPage;

    languageMap = {
        'en-US' : 'en',
        'zh-Hans-CN' : 'zh',
        'zh-Hant-TW' : 'zh',
        'ja' : 'ja',
        'ko' : 'ko',
        'fr' : 'fr',
        'pt-BR' : 'pt',
        'es' : 'es',
        'de' : 'de',
        'it' : 'it'
    }

    handleMessage() {
        this.keyword = window.location.pathname.includes('/global-search/') ? decodeURIComponent(window.location.pathname.split('/global-search/')[1]) : '';
        this.error = undefined;
        //this.firstRun = false;
        this.filters = [];
        this.productsBox = [];
        this.solutionBox = [];
        this.contentType = [];
        this.sourceType = [];
        this.selectedContentTypes = [];
        this.selectedSolutions = [];
        this.selectedProducts = [];
        this.selectedSource = [];
        this.sortOptions = [{label: 'Title', value: 'title.asc', checked: false, show: true},
                            {label: 'Date', value: 'modified.desc', checked: false, show: false},
                            {label: 'Relevance', value: 'globalrelevance.desc', checked: true, show: true}];
        this.precisionOptions = [{label: 'Exact Expression', value: 'exactexpression', checked: false},
                                {label: 'Same Phrase', value: 'inthesamephrase', checked: false},
                                {label: 'Every Word', value: 'everyword', checked: false},
                                {label: 'Default', value: 'Default', checked: true}];
        this.skip = 0;
        this.invalidsearch = false;
        this.noresultfound = false;
        this.allPage = true;
        // this.setLanguageForSearchTerm();
        this.getSearchResults('search','');
    }

    // setLanguageForSearchTerm(){
    //     console.log('User Language set to '+ this.getUserLang);
    //     for(var i = 0; i < this.languageOptions.length; i++) {
    //         if(this.languageOptions[i].key == this.getUserLang && this.languageOptions[i].checked == false){
    //             for(var j = 0; j < this.languageOptions.length; j++) {
    //                 if(this.languageOptions[j].checked == true){
    //                     this.languageOptions[j].checked = false;
    //                     break;
    //                 }
    //             }

    //             this.languageOptions[i].checked = true;
    //             break;
    //         }
    //     }
    // }

    getDetails() {
        // this.setLanguageForSearchTerm();
        getUser()
            .then(data => {
                try {
                    this.userdetails.userProfile = JSON.parse(data).profileName;
                    this.userdetails.userid = JSON.parse(data).Id;
                    this.userdetails.username = JSON.parse(data).userName;

                    // let user = JSON.parse(data);
                    // if(user.profileName !== 'Customer Community Profile'){
                    //     this.authenticatedUser = true;
                    // }
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

    getSearchResults(eventtype,filterItemSelected) {
        var showDateSort;
        document.title = 'Search Results | '+ this.keyword.trim();
        if(this.keyword.trim().length>=1){
            this.selectedSortOption = this.sortOptions.find(element => element.checked === true);
            this.precision = this.precisionOptions.find(element => element.checked === true);
            //let concept = '';
            //concept = this.selectedConcepts.reduce((accumulator, currentValue) => accumulator + '+['+currentValue+']', '');

            // let uLang = this.languageOptions.find(element => element.checked == true);
            // console.log(uLang);
            let langValue;
            if(this.languageMap[this.getUserLang] !== undefined){
                langValue = this.languageMap[this.getUserLang];
            }
            else{
                langValue = 'en';
            }
            this.isLoaded = false;
            let filter = {
                "method":"search.profile",
                "profile":"CCS",
                "query":{ 
                    "text" : this.keyword, 
                    "skipFrom" : this.skip < 0 ? 0 : this.skip, 
                    "sort" : this.selectedSortOption.value,
                    "precision" : this.precision.value,
                    "scmode" : "Smart",         //"Classic",
                    "questionLanguage" : "en",  //uLang.value,
                    "additionalWhereClause": "((treepath = '/Akamai.com/' and (documentlanguages='"+langValue+"' or documentlanguages='en')) or (treepath <> '/Akamai.com/'))",
                    "selections" : this.filters
                },
                "responseType":"SearchResult",
                "tabSearchValue":"/*",
            }
            
            getSearchResponse({ body : JSON.stringify(filter), apiName : 'results'})
                .then(data => {
                    try {
                        let resultDocs = JSON.parse(data);
                        this.error = undefined;
                        this.results = undefined;
                        this.spellCheck = undefined;
                        this.queryIntentResult = undefined;
                        this.sponsoredLinks = undefined;
                        this.filterOptions = [];
                        this.showQueryIntent=false;

                        if(resultDocs.Result.queryintents !== undefined){
                            this.queryIntentResult = JSON.parse(JSON.stringify(resultDocs.Result.queryintents[0].datasets));

                            if(this.queryIntentResult.productinfo.rows.length > 0 && this.queryIntentResult.productinfo.rows[0].sourcestr25 !== undefined) {
                                this.queryIntentResult.productinfo.title = this.queryIntentResult.productinfo.rows[0].sourcestr25; //this.queryIntentResult.productinfo.rows[0].sourcestr25.toUpperCase();
                                this.queryIntentResult.productinfo.url = this.queryIntentResult.productinfo.rows[0].url1;
                                this.queryIntentResult.productinfo.type = 'Documentation';
                                this.showQueryIntent=true;
                            }

                            if(this.queryIntentResult.releasenotes.rows.length > 0 && this.queryIntentResult.releasenotes.rows[0].sourcestr25 !== undefined) {
                                this.queryIntentResult.releasenotes.title = this.queryIntentResult.releasenotes.rows[0].sourcestr25;
                                this.queryIntentResult.releasenotes.url = this.queryIntentResult.releasenotes.rows[0].url1;
                                this.queryIntentResult.releasenotes.type = 'Documentation';
                                this.showQueryIntent=true;
                            }

                            if(this.queryIntentResult.productfeatures.rows.length > 0 && (this.queryIntentResult.productfeatures.rows[0].sourcestr27 !== undefined || this.queryIntentResult.productfeatures.rows[0].sourcestr28 !== undefined)) {
                                this.queryIntentResult.productfeatures.title = this.queryIntentResult.productfeatures.rows[0].sourcestr27 !== '' ? this.queryIntentResult.productfeatures.rows[0].sourcestr27 : this.queryIntentResult.productfeatures.rows[0].sourcestr28 ;
                                this.queryIntentResult.productfeatures.url = this.queryIntentResult.productfeatures.rows[0].url1;
                                this.queryIntentResult.productfeatures.type = 'Product Details';
                                this.showQueryIntent=true;
                            }

                            // Object.keys(resultDocs.Result.queryintents[0].datasets).forEach(function(key) {
                            //     console.log('Key : ' + key + ', Value : ' + JSON.stringify(resultDocs.Result.queryintents[0].datasets[key]));
                            //     //this.queryIntentResult = [...this.queryIntentResult, {key:key, value: resultDocs.Result.queryintents[0].datasets[key] }];
                            //     // this.queryIntentResult[key] = JSON.parse(JSON.stringify(this.queryIntentResult[key].rows[0].title));
                            //     // this.queryIntentResult.push({key:key, value:resultDocs.Result.queryintents[0].datasets[key] });
                            // });
                        // console.log(JSON.parse(JSON.stringify(this.queryIntentResult)));
                        }

                        if(resultDocs.Result.Links !== undefined) {
                            this.sponsoredLinks = resultDocs.Result.Links;
                        }

                        if(resultDocs.Result.DidYouMean !== undefined) {
                            this.spellCheck = resultDocs.Result.DidYouMean;
                            this.spellCheck.link = window.location.origin+'/customers/s/global-search/'+this.spellCheck.CorrectedText;
                        }

                        if(resultDocs.DocumentCount > 0 && resultDocs.Result.Docs.length > 0) {
                            this.filterBoxes = JSON.parse(JSON.stringify(resultDocs.Result.Boxes));

                            this.sourceType = this.filterBoxes.find(element => element.name === 'Akamai_Source');
                            if(this.sourceType === undefined) {
                                this.sourceType = {};
                                this.sourceType.items = [];
                            }
                            this.sourceType.show = this.sourceType.items.length > 0 ? true : false;

                            showDateSort = this.sortOptions.find(element => element.label === 'Date');
                            showDateSort.show = (this.sourceType.items.length === 1 && (this.sourceType.items[0].Name === 'Knowledge Articles' || this.sourceType.items[0].Name === 'Akamai Community')) ? true : false;
                            
                            this.contentType = this.filterBoxes.find(element => element.name === 'Akamai_ContentType');
                            if(this.contentType !== undefined) {
                                this.contentType.modifiedItems = this.contentType.items.slice(0, 5);
                            }    
                            else {
                                this.contentType = {};
                                this.contentType.items = [];
                            }
                            this.contentType.show = this.contentType.items.length > 0 ? true : false;
                            this.contentType.action = (this.contentType.items.length <= 5) ? '' : 'Show more';

                            this.solutionBox = this.filterBoxes.find(element => element.column === 'akamai_solutions');
                            if(this.solutionBox === undefined) {
                                this.solutionBox = {};
                                this.solutionBox.items = [];
                                this.solutionBox.show = false;
                            }
                            else{
                                this.solutionBox.show = this.solutionBox.items.length > 0 ? true : false;
                            }

                            this.productsBox = this.filterBoxes.find(element => element.column === 'akamai_products');
                            if(this.productsBox !== undefined) {
                                this.productsBox.modifiedItems = this.productsBox.items.slice(0, 5);
                                this.productsBox.show = this.productsBox.items.length > 0 ? true : false;
                                this.productsBox.action = (this.productsBox.items.length <= 5) ? '' : 'Show more';
                            }    
                            else {
                                this.productsBox = {};
                                this.productsBox.modifiedItems = [];
                                this.productsBox.show = false;
                                this.productsBox.action = '';
                            }

                            this.disablePrev = resultDocs.CurrentPage === 1 ? true : false;
                            this.disableNext = resultDocs.CurrentPage === resultDocs.PageCount ? true : false;
                            this.count = resultDocs.DocumentCount;
                            this.documentsThisPage = resultDocs.DocumentsThisPage;
                            this.documentsPerPage =  resultDocs.DocumentsPerPage;
                            this.results = resultDocs.Result.Docs;
                            this.currentPage = resultDocs.CurrentPage;
                            this.pageCount = resultDocs.PageCount;

                            for(let i=0; i<this.results.length; i++) {
                                if(this.results[i].Akamai_Source === 'Akamai Website'){
                                    this.results[i].Akamai_Source = this.results[i].Akamai_Source + ' (' + this.results[i].languages.toUpperCase() + ')';
                                }

                                // Document modified date
                                if(this.results[i].modified !== undefined){
                                    this.results[i].modified = this.results[i].source === 'Salesforce' ? this.results[i].modified.substring(0, 10) : '';
                                }

                                // Document rank
                                this.results[i].rank = ((resultDocs.CurrentPage - 1) * this.documentsPerPage) + (i+1); // page 1 ,20 doc-per-page : (1-1)*20 + (i+1)

                                if(this.results[i].largesummaryhtml !== undefined && this.results[i].smallsummaryhtml !==undefined) {
                                    if(this.results[i].largesummaryhtml.length > this.results[i].smallsummaryhtml.length){
                                        this.results[i].summaryhtml = this.results[i].largesummaryhtml.replace(/<b>/g, '<b style="background-color: yellow;font-weight: 400;font-style: normal;">');
                                    }
                                    else{
                                        this.results[i].summaryhtml =  this.results[i].smallsummaryhtml.replace(/<b>/g, '<b style="background-color: yellow;font-weight: 400;font-style: normal;">');
                                    }
                                }
                                else if(this.results[i].smallsummaryhtml !== undefined) {
                                    this.results[i].summaryhtml =  this.results[i].smallsummaryhtml.replace(/<b>/g, '<b style="background-color: yellow;font-weight: 400;font-style: normal;">');
                                }
                                else if(this.results[i].largesummaryhtml !== undefined) {
                                    this.results[i].summaryhtml =  this.results[i].largesummaryhtml.replace(/<b>/g, '<b style="background-color: yellow;font-weight: 400;font-style: normal;">');
                                }
                                else if(this.results[i].extracts !== undefined) {
                                    this.results[i].summaryhtml =  this.results[i].extracts.replace(/{b}/g, '<b style="background-color: yellow;font-weight: 400;font-style: normal;">').replace(/{nb}/g, '</b>');
                                }
                                let type = this.results[i].treepath.split('/');
                                type.pop();
                                this.results[i].type = type.pop();
                                if(this.results[i].type === 'Discussion') {
                                    this.results[i].isFeed = true;
                                    this.results[i].id = this.results[i].docid.split('|')[1];
                                    this.results[i].isQuestion = this.results[i].sourcestr37 === 'QuestionPost';
                                    if(this.results[i].sourcestr37 !== 'QuestionPost'){
                                        if(this.results[i].sourcestr36 === 'User')
                                            this.results[i].title = 'Post - ' + this.results[i].sourcestr35;
                                        else if(this.results[i].sourcestr36 === 'CollaborationGroup')
                                            this.results[i].title = 'Post in ' + this.results[i].sourcestr35;
                                    }
                                }
                            }
                        }
                        this.isLoaded = true;
                        this.captureAudit(this.keyword.trim(), eventtype, resultDocs.DocumentCount, filterItemSelected, '', '');
                        //window.setTimeout( this.setNav.bind(this), 100);
                        if(resultDocs.DocumentCount === 0){
                            this.noresultfound = true;
                        }
                    } catch(error) {
                        console.log('error');
                        console.log(error.message);
                        this.error = 'There was an error processing your request. Please try again. If the issue persists, please contact community@akamai.com';
                        this.isLoaded = true;
                        this.results = undefined;
                    }    
                })
                .catch(error => {
                    console.log('Api error');
                    console.log(error);
                    this.error = 'There was an error processing your request. Please try again. If the issue persists, please contact community@akamai.com';
                    this.isLoaded = true;
                    this.results = undefined;
                });
        }
        else{
            this.error = 'Your search term must have 1 or more characters.';
            this.isLoaded = true;
            this.results = undefined;
            this.invalidsearch = true;
        }
    }

    handleSourceSelect(event) {
        this.filters.push({
            'type':'multi',
            'box':'Akamai_Source',
            'items':[{'column':'Akamai_Source','op':'eq','value':event.currentTarget.dataset.name}]
        });
        this.allPage = false;
        this.skip = 0;
        this.getSearchResults('select.source',event.currentTarget.dataset.name);
        this.selectedSource.push(event.currentTarget.dataset.name);
    }

    handleContentTypeSelect(event){
        this.filters.push({
            'type':'multi',
            'box':'Akamai_ContentType',
            'items':[{'column':'Content_Type','op':'eq','value':event.currentTarget.dataset.name}]
        });
        this.allPage = false;
        this.skip = 0;
        this.getSearchResults('select.contenttype',event.currentTarget.dataset.name);
        this.selectedContentTypes.push(event.currentTarget.dataset.name);
    }

    handleSolutionSelect(event) {
        this.filters.push({
            'type':'multi',
            'box':'Akamai_Solutions',
            'items':[{'column':'akamai_solutions','op':'eq','value':event.currentTarget.dataset.name}]
        });
        this.allPage = false;
        this.skip = 0;
        this.getSearchResults('select.solution',event.currentTarget.dataset.name);
        this.selectedSolutions.push(event.currentTarget.dataset.name);
    }

    handleProductSelect(event) {
        this.filters.push({
            'type':'multi',
            'box':'Akamai_Products',
            'items':[{'column':'akamai_products','op':'eq','value':event.currentTarget.dataset.name}]
        });
        this.allPage = false;
        this.skip = 0;
        this.getSearchResults('select.product',event.currentTarget.dataset.name);
        this.selectedProducts.push(event.currentTarget.dataset.name);
    }

    handleRemoveSource(event) {
        if(this.filters.length!==0){
            this.filters = this.filters.filter(function(ele){ return ele.box !== "Akamai_Source"; });
            this.skip = 0;
            if(event.currentTarget.name === 'Knowledge Articles' || event.currentTarget.name === 'Akamai Community'){
                this.sortOptions = [{label: 'Title', value: 'title.asc', checked: false, show: true},
                                    {label: 'Date', value: 'modified.desc', checked: false, show: false},
                                    {label: 'Relevance', value: 'globalrelevance.desc', checked: true, show: true}];
            }
            this.getSearchResults('remove.source','');
            this.selectedSource = [];
        }
        if(this.filters.length===0){
            this.allPage = true;
        }
    }

    handleRemoveContentTypes() {
        if(this.filters.length!==0){
            this.filters = this.filters.filter(function(ele){ return ele.box !== "Akamai_ContentType"; });
            this.skip = 0;
            this.getSearchResults('remove.contenttype','');
            this.selectedContentTypes = [];
        }
        if(this.filters.length===0){
            this.allPage = true;
        }
    }

    handleRemoveSolutions() {
        if(this.filters.length!==0){
            this.filters = this.filters.filter(function(ele){ return ele.box !== "Akamai_Solutions"; });
            this.skip = 0;
            this.getSearchResults('remove.solution','');
            this.selectedSolutions = [];
        }
        if(this.filters.length===0){
            this.allPage = true;
        }
    }

    handleRemoveProducts() {
        if(this.filters.length!==0){
            this.filters = this.filters.filter(function(ele){ return ele.box !== "Akamai_Products"; });
            this.skip = 0;
            this.getSearchResults('remove.product','');
            this.selectedProducts = [];
        }
        if(this.filters.length===0){
            this.allPage = true;
        }
    }

    clearAllSelectedFilters(){
        this.filters = [];
        this.skip = 0;
        this.getSearchResults('remove.allFilters','');
        this.selectedContentTypes = [];
        this.selectedSolutions = [];
        this.selectedProducts = [];
        this.selectedSource = [];
        this.allPage = true;
    }

    handleSortMenuSelect(event) {
        this.sortOptions.map(element => {element.checked = false; return element;});
        let selectedOption = this.sortOptions.find(element => element.value === event.detail.value);
        selectedOption.checked = true;
        this.skip=0;
        this.getSearchResults('sort:'+selectedOption.label,'');
    }

    handlePrecisionMenuSelect(event) {
        this.precisionOptions.map(element => {element.checked = false; return element;});
        let precisionOptions = this.precisionOptions.find(element => element.value === event.detail.value);
        precisionOptions.checked = true;
        this.skip = 0;
        if(!this.noresultfound){
            this.getSearchResults('advanced:'+precisionOptions.label,'');
        }
        else{
            this.error = undefined;
            this.firstRun = false;
            this.noresultfound = false;
            this.allPage = false;
            this.getSearchResults('advanced:'+precisionOptions.label,'');
        }
    }

    // handleLanguageMenuSelect(event){
    //     this.languageOptions.map(element => {element.checked = false; return element;});
    //     let languageOptions = this.languageOptions.find(element => element.value === event.detail.value);
    //     languageOptions.checked = true;
    //     this.getSearchResults('language:'+languageOptions.label,'');
    // }

    handlePrevPageSearch() {
        if(this.currentPage > 1) {
            this.skip -= this.documentsPerPage;
            this.getSearchResults('click.page'+(this.currentPage - 1),'');
        }
    }

    handleNextPageSearch() {
        if(this.currentPage < this.pageCount) {
            this.skip += this.documentsPerPage;
            this.getSearchResults('click.page'+(this.currentPage + 1),'');
        }    
    }

    show_popup(){
        this.showpopup=true;
    }

    hide_popup(){
        this.showpopup=false;
    }

    showContentType(){
        if(this.contentType.action === 'Show more'){
            this.contentType.modifiedItems=this.contentType.items;
            this.contentType.action = 'Show less';
        }
        else if(this.contentType.action === 'Show less'){
            this.contentType.modifiedItems=this.contentType.items.slice(0, 5);
            this.contentType.action = 'Show more';
        }
        else {
            this.contentType.modifiedItems=this.contentType.items;
        }
    }

    showProducts(){
        if(this.productsBox.action === 'Show more'){
            this.productsBox.modifiedItems=this.productsBox.items;
            this.productsBox.action = 'Show less';
        }
        else if(this.productsBox.action === 'Show less'){
            this.productsBox.modifiedItems=this.productsBox.items.slice(0, 5);
            this.productsBox.action = 'Show more';
        }
        else {
            this.productsBox.modifiedItems=this.productsBox.items;
        }
    }

    connectedCallback() {
        if(! this.firstRun) {
            this.firstRun = true;
            this.getDetails();
            this.handleMessage();
        }
        window.addEventListener('replaceState', () => {
            this.handleMessage();
        });
    }

    captureInAudit(evt){
        this.captureAudit(this.keyword.trim(), 'click.resultlink', 0, evt.target.dataset.title, evt.target.dataset.rank,evt.target.dataset.source);
        window.open(evt.target.dataset.url, '_blank');
    }

    captureAudit(search_term, action, resultcount, itemCaptured, rank, source){
        let filter = {
            "method" : "dev.plugin",
            "plugin" : "insert_audit",
            "searchterm" : search_term.trim(),
            "action" : action,
            "userName" : this.userdetails.username,
            "userId" : this.userdetails.userid,
            "userProfile" : this.userdetails.userProfile,
            "hostname" : window.location.hostname,
            "resultcount" : resultcount,
            "item" : itemCaptured,
            "rank" : rank,
            "source" : source,
            "docId" : ""
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