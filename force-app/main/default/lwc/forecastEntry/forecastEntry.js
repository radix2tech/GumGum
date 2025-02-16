import { LightningElement, track,wire,api  } from 'lwc';
import getForecastEntries from '@salesforce/apex/ForecastController.getForecastEntries';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import processData from '@salesforce/apex/ForecastController.processData';
import runBatchJob from '@salesforce/apex/ForecastController.runBatchJob';
import getUsers from '@salesforce/apex/ForecastController.getUsers';
import getAARs from '@salesforce/apex/ForecastController.getAARs';
import createSplitOwner from '@salesforce/apex/ForecastController.createSplitOwner';
import removeAAR from '@salesforce/apex/ForecastController.removeAAR';
import AAR_Advertiser from '@salesforce/schema/Advertiser_Agency_Relationship__c.Advertiser__c';
import AAR_Agency from '@salesforce/schema/Advertiser_Agency_Relationship__c.Agency__c';
import submitForApproval from '@salesforce/apex/ForecastController.submitForApproval';
import { NavigationMixin } from 'lightning/navigation';
import getActiveCurrencies from '@salesforce/apex/ForecastController.getActiveCurrencies';
import FE_pageSize from '@salesforce/label/c.FE_pageSize';

export default class ForecastEntry extends NavigationMixin(LightningElement) {


    @track currentPage = 1;
    @track totalPages = 0;
    @track isPreviousDisabled = true;
    @track isNextDisabled = false;

    pageSize = FE_pageSize; // Number of rows per page
    totalRecords = 0;

    updatePaginationControls() {
        this.isPreviousDisabled = this.currentPage === 1;
        this.isNextDisabled = this.currentPage === this.totalPages;
    }

    handlePrevious() {
        if (this.currentPage > 1) {

            this.currentPage--;
            this.fetchData();

        }
    }

    handleNext() {
        if (this.currentPage < this.totalPages) {

            this.currentPage++;
            this.fetchData();

        }
    }


    //Seller Filter
    @track sellerPills = [];
    sellerLabelSet = new Set();

    handleSellerKeyDown(event) {
        if (event.key === 'Enter') {
            let pillInput = event.target.value;
            event.target.value = '';
            if (pillInput.trim()) {

                const newPill = {
                    id: this.sellerPills.length ? this.sellerPills[this.sellerPills.length - 1].id + 1 : 1,
                    label: pillInput,
                    label1: '%'+pillInput+'%'
                };
                this.sellerPills = [...this.sellerPills, newPill];
            }

            this.handleSellerInputSet();
            

        }
    }

    handleSellerRemovePill(event) {
        const pillId = parseInt(event.target.dataset.id, 10);
        this.sellerPills = this.sellerPills.filter(pill => pill.id !== pillId);
        this.handleSellerInputSet();
    }

    handleSellerInputSet(){
        this.sellerLabelSet = new Set();
        this.sellerPills.forEach(pill => {
            this.sellerLabelSet.add(pill.label1);
        });

        this.currentPage = 1;
        this.updatePaginationControls();

        this.fetchData();
    }

    //Advertiser Filter
    @track advertiserPills = [];
    advertiserLabelSet = new Set();

    handleAdvertiserKeyDown(event) {
        if (event.key === 'Enter') {
            let pillInput = event.target.value;
            event.target.value = '';
            if (pillInput.trim()) {

                const newPill = {
                    id: this.advertiserPills.length ? this.advertiserPills[this.advertiserPills.length - 1].id + 1 : 1,
                    label: pillInput,
                    label1: '%'+pillInput+'%'
                };
                this.advertiserPills = [...this.advertiserPills, newPill];
            }

            this.handleAdvertiserInputSet();
            

        }
    }

    handleAdvertiserRemovePill(event) {
        const pillId = parseInt(event.target.dataset.id, 10);
        this.advertiserPills = this.advertiserPills.filter(pill => pill.id !== pillId);
        this.handleAdvertiserInputSet();
    }

    handleAdvertiserInputSet(){
        this.advertiserLabelSet = new Set();
        this.advertiserPills.forEach(pill => {
            this.advertiserLabelSet.add(pill.label1);
        });
        
        this.currentPage = 1;
        this.updatePaginationControls();

        this.fetchData();
    }

    //Agency Filter
    @track agencyPills = [];
    agencyLabelSet = new Set();

    handleAgencyKeyDown(event) {
        if (event.key === 'Enter') {
            let pillInput = event.target.value;
            event.target.value = '';
            if (pillInput.trim()) {

                const newPill = {
                    id: this.agencyPills.length ? this.agencyPills[this.agencyPills.length - 1].id + 1 : 1,
                    label: pillInput,
                    label1: '%'+pillInput+'%'
                };
                this.agencyPills = [...this.agencyPills, newPill];
            }

            this.handleAgencyInputSet();
            

        }
    }

    handleAgencyRemovePill(event) {
        const pillId = parseInt(event.target.dataset.id, 10);
        this.agencyPills = this.agencyPills.filter(pill => pill.id !== pillId);
        this.handleAgencyInputSet();
    }

    handleAgencyInputSet(){
        this.agencyLabelSet = new Set();
        this.agencyPills.forEach(pill => {
            this.agencyLabelSet.add(pill.label1);
        });

        this.currentPage = 1;
        this.updatePaginationControls();

        this.fetchData();
    }

    //Type Filter
    @track typePills = [];
    typeLabelSet = new Set();

    handleTypeFilterChange(event) {
            let pillInput = event.target.value;
            event.target.value = '';
            if (pillInput.trim()) {

                const newPill = {
                    id: this.typePills.length ? this.typePills[this.typePills.length - 1].id + 1 : 1,
                    label: pillInput,
                    label1: pillInput
                };
                this.typePills = [...this.typePills, newPill];
            }

            this.handleTypeInputSet();

    }

    handleTypeRemovePill(event) {
        const pillId = parseInt(event.target.dataset.id, 10);
        this.typePills = this.typePills.filter(pill => pill.id !== pillId);
        this.handleTypeInputSet();
    }

    handleTypeInputSet(){
        this.typeLabelSet = new Set();
        this.typePills.forEach(pill => {
            this.typeLabelSet.add(pill.label1);
        });

        this.currentPage = 1;
        this.updatePaginationControls();

        this.fetchData();
    }


    @track sortBy;
    @track sortDirection;

    get isSellerSortedAsc() {
        return this.sortBy === 'Seller' && this.sortDirection === 'asc';
    }
    get isSellerSortedDesc() {
        return this.sortBy === 'Seller' && this.sortDirection === 'desc';
    }

    get isAdvertiserSortedAsc() {
        return this.sortBy === 'Advertiser' && this.sortDirection === 'asc';
    }
    get isAdvertiserSortedDesc() {
        return this.sortBy === 'Advertiser' && this.sortDirection === 'desc';
    }

    get isAgencySortedAsc() {
        return this.sortBy === 'Agency' && this.sortDirection === 'asc';
    }
    get isAgencySortedDesc() {
        return this.sortBy === 'Agency' && this.sortDirection === 'desc';
    }

     handleSort(event) {
        const field = event.currentTarget.dataset.field;
        const isSameField = this.sortBy === field;
        this.sortDirection = isSameField
        ? this.sortDirection === 'asc'
            ? 'desc'
            : 'asc'
        : 'asc';
        this.sortBy = field;

        this.sortData(field, this.sortDirection);
    }

    sortData(field, direction) {
        const parseValue = (value) =>
        typeof value === 'string' ? value.toLowerCase() : value;
        const isAscending = direction === 'asc';

        this.returnData = [...this.returnData].sort((a, b) => {
        const valA = parseValue(a[field]);
        const valB = parseValue(b[field]);

        if (valA < valB) return isAscending ? -1 : 1;
        if (valA > valB) return isAscending ? 1 : -1;
        return 0;
        });
    }

    //Channel Filter
    @track channelPills = [];
    channelLabelSet = new Set();

    handleChannelFilterChange(event) {
            let pillInput = event.target.value;
            event.target.value = '';
            if (pillInput.trim()) {

                const newPill = {
                    id: this.channelPills.length ? this.channelPills[this.channelPills.length - 1].id + 1 : 1,
                    label: pillInput,
                    label1: pillInput
                };
                this.channelPills = [...this.channelPills, newPill];
            }

            this.handleChannelInputSet();

    }

    handleChannelRemovePill(event) {
        const pillId = parseInt(event.target.dataset.id, 10);
        this.channelPills = this.channelPills.filter(pill => pill.id !== pillId);
        this.handleChannelInputSet();
    }

    handleChannelInputSet(){
        this.channelLabelSet = new Set();
        this.channelPills.forEach(pill => {
            this.channelLabelSet.add(pill.label1);
        });

        this.currentPage = 1;
        this.updatePaginationControls();

        this.fetchData();
    }

    

    @track currencyOptions = [];
    @track selectedCurrency;

    @wire(getActiveCurrencies)
    wiredCurrencies({ error, data }) {
        if (data) {
            // Map currency data to combobox options
            this.currencyOptions = data.map(currency => ({
                label: currency,
                value: currency
            }));
        } else if (error) {
            console.error('Error fetching currencies', error);
        }
    }

    handleCurrencyChange(event) {

        const value = event.target.value;
        
        const forecastId = event.target.dataset.id;  // Gets the dynamic ID
        const rowId = event.target.dataset.row;  // Gets the dynamic name


        // Loop through the returnData array to find the correct row
        for (let i = 0; i < this.returnData.length; i++) {
            if (this.returnData[i].Id === rowId) {
                for(let j = 0; j < this.returnData[i].ForecastList.length; j++){
                    if(this.returnData[i].ForecastList[j].Id == forecastId){
                        this.returnData[i].ForecastList[j].CurrencyIsoCode = value;
                        this.returnData[i].ForecastList[j].isChanged = true;
                    }
                }
            }
        }
        this.isChanged = true;
    }

    // Specify the fields to display in the form
    fields = [AAR_Advertiser, AAR_Agency];

    @api recordId;
    @track disableBatchButton = true;
    @track batchButtonLabel = 'Refresh Data';
    deletedForecastList = [];
    @track CumulativeData = [];
    @track isLoading = false;
    @track currencyCode = 'USD';
    @track currencySymbol ;
    @track searchKey = '';
    @track userOptions = [];
    @track isDropdownVisible = false;
    @track isNoData = false;
    @track SelectedAdvertiserName;
    @track SelectedAdvertiserId;
    @track SelectedOwnerId;
    @track title;
    @track isManager = false;
    @track isChanged = false;
    @track filterValue = '';
    @track returnData;

    // Define the picklist options
    @track products = [
        { label: 'Core Media', value: 'Core Media' },
        { label: 'CTV', value: 'CTV' },
        { label: 'OLV', value: 'OLV' },
        { label: 'Data', value: 'Data' },
    ];

    // Define the picklist options
    @track filterOptions1 = [
        { label: 'New', value: 'New' },
        { label: 'Renewal', value: 'Renewal' }
    ];

    @track filterOptions2 = [
        { label: 'Direct', value: 'Direct' },
        { label: 'Programmatic', value: 'Programmatic' }
    ];


    disconnectedCallback() {
        this.stopPolling(); // Stop polling when component is removed from DOM
    }

    //get the search key and return users
    handleInputChange(event) {
        // Capture the user input
        this.searchKey = event.target.value;

        // Fetch users based on search key
        if (this.searchKey) {
            getUsers({ searchTerm: this.searchKey })
                .then(result => {
                    // Convert user records to dropdown options
                    this.userOptions = result.map(user => {
                        return { label: user.Name, value: user.Id };
                    });
                    this.isDropdownVisible = this.userOptions.length > 0;
                    this.isNoData = result.length === 0;
                })
                .catch(error => {
                    this.userOptions = [];
                    this.isDropdownVisible = false;
                    console.error('Error fetching users:', error);
                });
        } else {
            // Clear the dropdown when no input
            this.userOptions = [];
            this.isDropdownVisible = false;
            this.isNoData = false;
        }
    }

    // Capture the selected user
    handleUserSelection(event) {
        const selectedUserLabel = event.target.innerText;
        const selectedUser = this.userOptions.find(user => user.label === selectedUserLabel);
        
        if (selectedUser) {
            this.SelectedOwnerId = selectedUser.value;
            this.searchKey = selectedUser.label; // Set selected user in the input field
            this.isDropdownVisible = false; // Hide dropdown after selection
        }
    }

    showDropdown() {
        // Show dropdown when input is focused
        this.isDropdownVisible = this.userOptions.length > 0;
    }

    hideDropdown() {
        // Hide dropdown when input loses focus
        // Using a slight timeout to allow for the selection click
        setTimeout(() => {
            this.isDropdownVisible = false;
        }, 200);
    }

    @track previousYear;
    @track currentYear;
    @track nextYear;
    @track forecastYear;

    async fetchData(){
        this.isLoading = true;

        console.log('####  this.sellerLabelSet '+ Array.from(this.sellerLabelSet));
        console.log('####  this.advertiserLabelSet '+ Array.from(this.advertiserLabelSet));
        console.log('####  this.agencyLabelSet '+ Array.from(this.agencyLabelSet));
        console.log('####  this.typeLabelSet '+ Array.from(this.typeLabelSet));
        console.log('####  this.channelLabelSet '+ Array.from(this.channelLabelSet));

        const objResult = await getForecastEntries({ recordId:this.recordId,pageSize: this.pageSize, pageNumber: this.currentPage, sellerLabelSet : Array.from(this.sellerLabelSet), advertiserLabelSet : Array.from(this.advertiserLabelSet), agencyLabelSet : Array.from(this.agencyLabelSet),typeLabelSet :  Array.from(this.typeLabelSet),channelLabelSet :  Array.from(this.channelLabelSet) });
        this.returnData = objResult.returnDataList;

        this.totalRecords = objResult.totalRecords;
        this.totalPages = Math.ceil(this.totalRecords / this.pageSize);
        this.updatePaginationControls();

        this.currencySymbol = objResult.currencySymbol;
        this.CumulativeData = objResult.data;
        
        this.isLoading = false;
    }

    async connectedCallback() {

        const objResult = await getForecastEntries({ recordId:this.recordId,pageSize: this.pageSize, pageNumber: this.currentPage , sellerLabelSet : null, advertiserLabelSet : null, agencyLabelSet : null, typeLabelSet : null, channelLabelSet : null});
        this.returnData = objResult.returnDataList;

        this.totalRecords = objResult.totalRecords;
        this.totalPages = Math.ceil(this.totalRecords / this.pageSize);
        this.updatePaginationControls();

        this.currencySymbol = objResult.currencySymbol;
        this.CumulativeData = objResult.data;
        this.isManager = objResult.isManager;
        if(this.isManager == true){
            this.title = 'Manager View - Forecast Period';
        }else{
            this.title = 'Seller View - Forecast Period';
        }

        this.currentYear = new Date().getFullYear();
        this.nextYear = this.currentYear+1;
        this.forecastYear = this.currentYear;
        this.previousYear = this.currentYear-1;
        
        if(this.isLastQuarter()){
            this.forecastYear = this.forecastYear + 1; 
        }
        this.runBatch();

    }

    isLastQuarter() {
        const currentMonth = new Date().getMonth() + 1; // getMonth() returns 0-based month
        return currentMonth >= 10 && currentMonth <= 12;
    }

    // Function to handle submission of forecasts
    async submit() {

        this.isLoading = true;
        await processData({ returnDataList:this.returnData, deletedForecastList : this.deletedForecastList}); // Pass inputData as a parameter
  
        // Simulate saving and show a toast notification (in a real use case, you would call Apex)
        const evt = new ShowToastEvent({
            title: "Success",
            message: "Forecasts submitted successfully!",
            variant: "success"
        });
        this.dispatchEvent(evt);

        /*const objResult = await getForecastEntries({ recordId:this.recordId,pageSize: this.pageSize, pageNumber: this.currentPage});
        this.returnData = objResult.returnDataList;
        this.CumulativeData = objResult.data;*/
        this.fetchData();

        this.isLoading = false;
    
    }

    handleChannelChange(event) {
        const selectedValue = event.detail.value;
        const rowId = event.target.dataset.id;

        // Loop through the returnData array to find the correct row
        for (let i = 0; i < this.returnData.length; i++) {
            if (this.returnData[i].Id === rowId) {
                this.returnData[i].Channel = selectedValue;
                this.returnData[i].isChanged = true;
                break;
            }
        }
        this.isChanged = true;
    }

    handleTypeChange(event){
        const TradingDeal = event.target.checked;
        const rowId = event.target.dataset.id;
        console.log('#### rowId '+rowId);
        console.log('#### TradingDeal '+TradingDeal);
        // Loop through the returnData array to find the correct row
        for (let i = 0; i < this.returnData.length; i++) {
            if (this.returnData[i].Id === rowId) {
                this.returnData[i].TradingDeal = TradingDeal;
                this.returnData[i].isChanged = true;
                break;
            }
        }
        this.isChanged = true;
    }

    handleProductChange(event){
        const selectedValue = event.detail.value;
        
        const forecastId = event.target.dataset.id;  // Gets the dynamic ID
        const rowId = event.target.dataset.row;  // Gets the dynamic name

        // Loop through the returnData array to find the correct row
        for (let i = 0; i < this.returnData.length; i++) {
            if (this.returnData[i].Id === rowId) {
                for(let j = 0; j < this.returnData[i].ForecastList.length; j++){
                    if(this.returnData[i].ForecastList[j].Id == forecastId){
                        this.returnData[i].ForecastList[j].name = selectedValue;
                        this.returnData[i].ForecastList[j].isChanged = true;
                    }
                }
            }
        }
        this.isChanged = true;
    }

    handleQ1Change(event){
        const value = event.target.value;
        
        const forecastId = event.target.dataset.id;  // Gets the dynamic ID
        const rowId = event.target.dataset.row;  // Gets the dynamic name


        // Loop through the returnData array to find the correct row
        for (let i = 0; i < this.returnData.length; i++) {
            if (this.returnData[i].Id === rowId) {
                for(let j = 0; j < this.returnData[i].ForecastList.length; j++){
                    if(this.returnData[i].ForecastList[j].Id == forecastId){
                        this.returnData[i].ForecastList[j].q1 = value;
                        this.returnData[i].ForecastList[j].isChanged = true;
                    }
                }
            }
        }
        this.isChanged = true;
    }

    handleQ2Change(event){
        const value = event.target.value;
        
        const forecastId = event.target.dataset.id;  // Gets the dynamic ID
        const rowId = event.target.dataset.row;  // Gets the dynamic name


        // Loop through the returnData array to find the correct row
        for (let i = 0; i < this.returnData.length; i++) {
            if (this.returnData[i].Id === rowId) {
                for(let j = 0; j < this.returnData[i].ForecastList.length; j++){
                    if(this.returnData[i].ForecastList[j].Id == forecastId){
                        this.returnData[i].ForecastList[j].q2 = value;
                        this.returnData[i].ForecastList[j].isChanged = true;
                    }
                }
            }
        }
        this.isChanged = true;
    }

    handleQ3Change(event){
        const value = event.target.value;
        
        const forecastId = event.target.dataset.id;  // Gets the dynamic ID
        const rowId = event.target.dataset.row;  // Gets the dynamic name


        // Loop through the returnData array to find the correct row
        for (let i = 0; i < this.returnData.length; i++) {
            if (this.returnData[i].Id === rowId) {
                for(let j = 0; j < this.returnData[i].ForecastList.length; j++){
                    if(this.returnData[i].ForecastList[j].Id == forecastId){
                        this.returnData[i].ForecastList[j].q3 = value;
                        this.returnData[i].ForecastList[j].isChanged = true;
                    }
                }
            }
        }
        this.isChanged = true;
    }

    handleQ4Change(event){
        const value = event.target.value;
        
        const forecastId = event.target.dataset.id;  // Gets the dynamic ID
        const rowId = event.target.dataset.row;  // Gets the dynamic name


        // Loop through the returnData array to find the correct row
        for (let i = 0; i < this.returnData.length; i++) {
            if (this.returnData[i].Id === rowId) {
                for(let j = 0; j < this.returnData[i].ForecastList.length; j++){
                    if(this.returnData[i].ForecastList[j].Id == forecastId){
                        this.returnData[i].ForecastList[j].q4 = value;
                        this.returnData[i].ForecastList[j].isChanged = true;
                    }
                }
            }
        }
        this.isChanged = true;
    }

    handleQ11Change(event){
        const value = event.target.value;
        
        const forecastId = event.target.dataset.id;  // Gets the dynamic ID
        const rowId = event.target.dataset.row;  // Gets the dynamic name

        console.log('### forecastId'+forecastId);
        console.log('### rowId'+rowId);
        // Loop through the returnData array to find the correct row
        for (let i = 0; i < this.returnData.length; i++) {
            if (this.returnData[i].Id === rowId) {
                for(let j = 0; j < this.returnData[i].ForecastList.length; j++){
                    if(this.returnData[i].ForecastList[j].Id == forecastId){
                        this.returnData[i].ForecastList[j].q11 = value;
                        this.returnData[i].ForecastList[j].isChanged = true;
                    }
                }
            }
        }
        this.isChanged = true;
    }

    handleQ21Change(event){
        const value = event.target.value;
        
        const forecastId = event.target.dataset.id;  // Gets the dynamic ID
        const rowId = event.target.dataset.row;  // Gets the dynamic name


        // Loop through the returnData array to find the correct row
        for (let i = 0; i < this.returnData.length; i++) {
            if (this.returnData[i].Id === rowId) {
                for(let j = 0; j < this.returnData[i].ForecastList.length; j++){
                    if(this.returnData[i].ForecastList[j].Id == forecastId){
                        this.returnData[i].ForecastList[j].q21 = value;
                        this.returnData[i].ForecastList[j].isChanged = true;
                    }
                }
            }
        }
        this.isChanged = true;
    }

    handleQ31Change(event){
        const value = event.target.value;
        
        const forecastId = event.target.dataset.id;  // Gets the dynamic ID
        const rowId = event.target.dataset.row;  // Gets the dynamic name


        // Loop through the returnData array to find the correct row
        for (let i = 0; i < this.returnData.length; i++) {
            if (this.returnData[i].Id === rowId) {
                for(let j = 0; j < this.returnData[i].ForecastList.length; j++){
                    if(this.returnData[i].ForecastList[j].Id == forecastId){
                        this.returnData[i].ForecastList[j].q31 = value;
                        this.returnData[i].ForecastList[j].isChanged = true;
                    }
                }
            }
        }
        this.isChanged = true;
    }

    handleQ41Change(event){
        const value = event.target.value;
        
        const forecastId = event.target.dataset.id;  // Gets the dynamic ID
        const rowId = event.target.dataset.row;  // Gets the dynamic name


        // Loop through the returnData array to find the correct row
        for (let i = 0; i < this.returnData.length; i++) {
            if (this.returnData[i].Id === rowId) {
                for(let j = 0; j < this.returnData[i].ForecastList.length; j++){
                    if(this.returnData[i].ForecastList[j].Id == forecastId){
                        this.returnData[i].ForecastList[j].q41 = value;
                        this.returnData[i].ForecastList[j].isChanged = true;
                    }
                }
            }
        }
        this.isChanged = true;
    }


    handleDelete(event) {
        const buttonId = event.target.dataset.id;  // Gets the dynamic ID
        const rowId = event.target.dataset.row;  // Gets the dynamic name

        if(buttonId.length == 18){
            this.deletedForecastList.push(buttonId);
        }


        // Loop through the returnData array to find the correct row
        for (let i = 0; i < this.returnData.length; i++) {
            if (this.returnData[i].Id === rowId) {
                // Update the ForecastList by filtering out the item with the matching buttonId
                this.returnData[i].ForecastList = this.returnData[i].ForecastList.filter(item => item.Id !== buttonId);

                if(this.returnData[i].ForecastList && this.returnData[i].ForecastList.length != 0 ){
                    this.returnData[i].ForecastList[this.returnData[i].ForecastList.length-1].displayAdd = true;
                }
                else{
                    this.returnData[i].displayProducts =false;
                }
                break;  // Exit the loop once the correct row is found and updated

            }
        }
        this.isChanged = true;

        

    }

    handleAdd(event) {
        const rowId = event.target.dataset.id;  // Gets the dynamic ID
        console.log('### rowId '+rowId);
        // Loop through returnData to find the correct row
        for (let i = 0; i < this.returnData.length; i++) {
            if (this.returnData[i].Id === rowId) {



                // Create a new blank forecast item
                const newForecastItem = {
                    Id: `${Date.now()}`, // Unique ID based on current timestamp
                    name: 'Core Media', 
                    /*q11: 0.0,
                    q21: 0.0,
                    q31: 0.0,
                    q41: 0.0,*/
                    displayAdd:true,
                    isChanged:true
                };
                
                if(this.returnData[i].ForecastList.length == 3 && this.isManager == false){
                    newForecastItem.displayAdd = false;
                }

                // Add the new forecast item to the ForecastList
                this.returnData[i].ForecastList.push(newForecastItem);
                if(this.returnData[i].ForecastList.length > 1){
                    this.returnData[i].ForecastList[this.returnData[i].ForecastList.length-2].displayAdd = false;
                }
                this.returnData[i].displayProducts =true;
                break; // Exit loop after updating the relevant row
            }
        }

        this.isChanged = true;
        // Perform actions based on the clicked button data
    }

    toggleRow(event) {
        const rowId = event.target.dataset.id;

        // Loop through returnData to find the correct row
        for (let i = 0; i < this.returnData.length; i++) {


            if (this.returnData[i].Id === rowId) {
                this.returnData[i].isExpanded = !this.returnData[i].isExpanded;
                break; // Exit loop after updating the relevant row
            }
        }

    }


    pollingInterval; // Variable to store the interval ID

    startPolling() {
        this.pollingInterval = setInterval(() => {
            this.runBatch();
        }, 15000); // Call every 15 seconds
    }

    async stopPolling() {
        clearInterval(this.pollingInterval); // Clear the interval to stop polling
        this.fetchData();
    }


    async runBatch(){

        const objResult = await runBatchJob({disableBatchButton : this.disableBatchButton});
  
        if(objResult == true){
            this.disableBatchButton = false; // Disable button
            this.batchButtonLabel = 'Refresh Data';
            await this.fetchData();
            this.stopPolling();
        }

        if(this.disableBatchButton == false && objResult == false){
            this.disableBatchButton = true; // Disable button
            this.batchButtonLabel = 'Refreshing Data';
            this.startPolling(); // Start polling when component is connected
        }
    }

    @track isModalOpen2 = false;
    @track duplicateRecordLinks = [];

    handleError2(event) {
        // Check if we have a duplicate rule error

        const errors = event.detail.output.errors;
        const matchRecordIds = [];

        /*for (const error of errors) {
            if (error.errorCode === "DUPLICATES_DETECTED" && error.duplicateRecordError) {
                return error.duplicateRecordError.matchResults.map(result => result.matchRecordIds).flat();
            }
        }*/

        // Check if we have a duplicate rule error and extract matching IDs
        errors.forEach(error => {
            if (error.errorCode === "DUPLICATES_DETECTED" && error.duplicateRecordError) {
                error.duplicateRecordError.matchResults.forEach(result => {
                    matchRecordIds.push(...result.matchRecordIds);
                });
            }
        });

        if (matchRecordIds.length > 0) {
            event.preventDefault();
            this.errorMessage = "Duplicate found! Use one of these records:";
            this.duplicateRecordLinks = matchRecordIds.map(
                recordId => ({
                    id: recordId,
                    url: `/lightning/r/${recordId}/view`
                })
            );
        }

    }


    // To store and display error messages
    @track errorMessage;

    async handleSuccess2(event) {
        const evt = new ShowToastEvent({
            title: "Record Created",
            message: "Advertiser Agency Relationship Created",
            variant: "success"
        });
        this.dispatchEvent(evt);
        this.isModalOpen2 = false;
        this.errorMessage = null;
        this.duplicateRecordLinks = [];
        this.runBatch();
        this.fetchData();

    }

    // Method to open the modal
    openModal2() {
        this.isModalOpen2 = true;
    }

    // Method to close the modal
    closeModal2() {
        this.isModalOpen2 = false;
    }


    @track isModalOpen = false;

    // Method to open the modal
    openModal(event) {
        this.isModalOpen = true;
        const rowId = event.target.dataset.id;
        const name = event.target.dataset.name;
        this.SelectedAdvertiserName = name; 
        this.SelectedAdvertiserId = rowId;
    }

    // Method to close the modal
    closeModal() {
        this.isModalOpen = false;
        this.SelectedAdvertiserName = ''; 
        this.SelectedAdvertiserId = '';
    }


    @track isModalOpen1 = false;
    @track searchKey1 = '';
    @track AAROptions = [];
    @track isDropdownVisible1 = false;
    @track isNoData1 = false;
    @track SelectedAdvertiserName;
    @track SelectedAdvertiserId;
    @track SelectedAARId;

    // Method to open the modal
    openModal1(event) {
        this.isModalOpen1 = true;
    }

    // Method to close the modal
    closeModal1() {
        this.isModalOpen1 = false;
        this.searchKey1 = '';
    }


    handleInputChange1(event) {
        // Capture the user input
        this.searchKey1 = event.target.value;

        // Fetch users based on search key
        if (this.searchKey1) {
            getAARs({ searchTerm: this.searchKey1 })
                .then(result => {

                    // Convert AAR records to dropdown options
                    this.AAROptions = result.map(AAR => {
                        return { label: AAR.Name +' '+AAR.Advertiser_Agency_Name__c, value: AAR.Id };
                    });
                    this.isDropdownVisible1 = this.AAROptions.length > 0;
                    this.isNoData1 = result.length === 0;
                })
                .catch(error => {
                    this.AAROptions = [];
                    this.isDropdownVisible1 = false;
                    console.error('Error fetching users:', error);
                });
        } else {
            // Clear the dropdown when no input
            this.AAROptions = [];
            this.isDropdownVisible1 = false;
            this.isNoData1 = false;
        }
    }

    showDropdown1() {
        // Show dropdown when input is focused
        this.isDropdownVisible1 = this.AAROptions.length > 0;
    }

    hideDropdown1() {
        // Hide dropdown when input loses focus
        // Using a slight timeout to allow for the selection click
        setTimeout(() => {
            this.isDropdownVisible1 = false;
        }, 200);
    }

    handleUserSelection1(event) {
        // Capture the selected user
        const selectedAARLabel = event.target.innerText;
        const selectedAAR = this.AAROptions.find(user => user.label === selectedAARLabel);
        
        if (selectedAAR) {
            this.SelectedAARId = selectedAAR.value;
            this.searchKey1 = selectedAAR.label; // Set selected user in the input field
            this.isDropdownVisible1 = false; // Hide dropdown after selection
        }
    }



    // Method to handle save action
    async handleSave1() {
        // Add save logic here if needed

        this.isLoading = true;
        await createSplitOwner({ recordId: this.SelectedAARId});

        this.fetchData();

        this.isLoading = false;

        this.closeModal1(); // Close the modal after saving
    }

    // Method to handle save action
    handleSave() {
        // Add save logic here if needed

        submitForApproval({ recordId: this.SelectedAdvertiserId , selectedNewOwner: this.SelectedOwnerId })
        .then(result => {
            // Convert user records to dropdown options
            this.userOptions = result.map(user => {
                return { label: user.Name, value: user.Id };
            });
            this.isDropdownVisible = this.userOptions.length > 0;
            this.isNoData = result.length === 0;
        })
        .catch(error => {
            this.userOptions = [];
            this.isDropdownVisible = false;
            console.error('Error fetching users:', error);
        });

        this.closeModal(); // Close the modal after saving
    }

    async removeAAR(event){
        
        this.isLoading = true;

        const rowId = event.target.dataset.id;
        await removeAAR({ recordId: rowId});

        this.fetchData();

        this.isLoading = false;
  
    }

    handleNavigate(event) {
        const rowId = event.target.dataset.id;

        // Check if rowId exists to prevent errors
        if (rowId) {
            // Use the NavigationMixin to navigate to the record page
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: rowId,
                    objectApiName: 'Account', // Change 'Account' to your object API name if different
                    actionName: 'view'
                }
            });
        } else {
            console.error('Row ID is not defined');
        }
    }

}