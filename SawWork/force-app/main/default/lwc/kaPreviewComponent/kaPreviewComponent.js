import { LightningElement, wire, api } from 'lwc';
import linkKAToIncident from '@salesforce/apex/HD_KA_Viewer_Controller.linkKAToIncident';
import removeLinkBWKAAndIncident from '@salesforce/apex/HD_KA_Viewer_Controller.removeLinkBWKAAndIncident';
import getAllLinkedKnowledgeArticles from '@salesforce/apex/HD_KA_Viewer_Controller.getAllLinkedKnowledgeArticles';
import getFavouriteKAs from '@salesforce/apex/HD_KA_Viewer_Controller.getFavouriteKAs';

export default class KaPreviewComponent extends LightningElement {
    @api recordId;
    @api flexipageRegionWidth;
    linkedKnowledgeArticles;
    isError;
    errorMessage;
    isLoading;
    favourites;

    @wire(getAllLinkedKnowledgeArticles, { incidentId: '$recordId' })
    getKAsCallback({ error, data }) {
        if (data) {
            let kas = JSON.parse(data);
            if (kas) {
                this.linkedKnowledgeArticles = [];
                kas.forEach(ka => {
                    this.linkedKnowledgeArticles = [...this.linkedKnowledgeArticles, {
                        type: 'icon',
                        label: ka.BMCServiceDesk__Title__c,
                        name: 'iconpill',
                        href: '/' + ka.Id,
                        iconName: 'standard:knowledge',
                        isLink: true
                    }];
                });
            }
        }
        else if (error) {
            this.isError = true;
            this.errorMessage = error.body.message;
        }
    }

    @wire(getFavouriteKAs)
    favouritesCallback({ error, data }) {
        if (data) {
            this.favourites = JSON.parse(data);
        }
        else if (error) {
            this.isError = true;
            this.errorMessage = error.body.message;
        }
    }

    get showPillContainer() {
        return this.linkedKnowledgeArticles && this.linkedKnowledgeArticles.length > 0;
    }

    handleItemLink(event) {
        if (!this.linkedKnowledgeArticles) {
            this.linkedKnowledgeArticles = [];
        }

        let isAlreadyAdded;
        this.linkedKnowledgeArticles.forEach(linkedKA => {
            if (linkedKA.href === '/' + event.detail.Id) {
                isAlreadyAdded = true;
            }
        });

        this.isError = isAlreadyAdded;
        this.errorMessage = (isAlreadyAdded) ? 'Knowledge Article already linked' : '';
        if (isAlreadyAdded) {
            return;
        }

        this.isLoading = true;
        linkKAToIncident({ knowledgeArticleId: event.detail.Id, incidentId: this.recordId })
            .then(() => {
                this.isLoading = false;
                let existingItems = [];
                existingItems = [...this.linkedKnowledgeArticles, {
                    href: '/' + event.detail.Id,
                    type: 'icon',
                    label: event.detail.Name,
                    name: 'iconpill',
                    iconName: event.detail.Icon,
                    variant: 'circle',
                    isLink: true
                }];
                this.linkedKnowledgeArticles = existingItems;
                this.isError = false;
                this.errorMessage = '';
            })
            .catch(error => {
                this.isError = true;
                this.errorMessage = error.body.message;
                this.isLoading = false;
            });
    }

    handleItemRemove(event) {
        this.isLoading = true;
        removeLinkBWKAAndIncident({ knowledgeArticleId: event.detail.item.src.replace('/', ''), incidentId: this.recordId })
            .then(() => {
                this.isLoading = false;
                let existingItems = [];
                existingItems = [...this.linkedKnowledgeArticles];
                const index = event.detail.index;
                existingItems.splice(index, 1);
                this.linkedKnowledgeArticles = existingItems;
                this.isError = false;
                this.errorMessage = '';
            })
            .catch(error => {
                this.isError = true;
                this.errorMessage = error.body.message;
                this.isLoading = false;
            });
    }
}