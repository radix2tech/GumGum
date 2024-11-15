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

export default class ForecastEntry extends LightningElement {

    // Specify the fields to display in the form
    fields = [AAR_Advertiser, AAR_Agency];

    @api recordId;
    @track disableBatchButton = true;
    @track batchButtonLabel = 'Refresh Data';
    deletedForecastList = [];
    @track CumulativeData = [];
    @track isLoading = false;
    @track currencyCode = 'USD';
    @track currencySymbol = '$';
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
    @track options2 = [
        { label: 'New', value: 'New' },
        { label: 'Renewal', value: 'Renewal' }
    ];

    @track options = [
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

    @track currentYear;
    @track nextYear;

    async connectedCallback() {

        const objResult = await getForecastEntries({ recordId:this.recordId});
        this.returnData = objResult.returnDataList;
        this.CumulativeData = objResult.data;
        this.isManager = objResult.isManager;
        if(this.isManager == true){
            this.title = 'Manager View - Forecast Period';
        }else{
            this.title = 'Seller View - Forecast Period';
        }

        this.currentYear = new Date().getFullYear();
        this.nextYear = this.currentYear+1;
        this.runBatch();
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

        const objResult = await getForecastEntries({ recordId:this.recordId});
        this.returnData = objResult.returnDataList;
        this.CumulativeData = objResult.data;

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

        // Loop through returnData to find the correct row
        for (let i = 0; i < this.returnData.length; i++) {
            if (this.returnData[i].Id === rowId) {



                // Create a new blank forecast item
                const newForecastItem = {
                    Id: `${Date.now()}`, // Unique ID based on current timestamp
                    name: 'Core Media', 
                    /*q1: 0.0,
                    q2: 0.0,
                    q3: 0.0,
                    q4: 0.0,*/
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
        const objResult = await getForecastEntries({ recordId:this.recordId});
        this.returnData = objResult.returnDataList;
        this.CumulativeData = objResult.data;
    }


    async runBatch(){

        const objResult = await runBatchJob({disableBatchButton : this.disableBatchButton});
  
        if(objResult == true){
            this.disableBatchButton = false; // Disable button
            this.batchButtonLabel = 'Refresh Data';
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

        const objResult = await getForecastEntries({ recordId:this.recordId});
        this.returnData = objResult.returnDataList;
        this.CumulativeData = objResult.data;

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

        const objResult = await getForecastEntries({ recordId:this.recordId});
        this.returnData = objResult.returnDataList;
        this.CumulativeData = objResult.data;

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

        const objResult = await getForecastEntries({ recordId:this.recordId});
        this.returnData = objResult.returnDataList;
        this.CumulativeData = objResult.data;

        this.isLoading = false;
  
    }

    applyFilter() {
        if(this.value9 == 'Advertiser'){
            // Loop through the returnData array to find the correct row
            for (let i = 0; i < this.returnData.length; i++) {
                if ( this.returnData[i].Advertiser && this.returnData[i].Advertiser.toLowerCase().includes(this.filterText.toLowerCase())) {
                    this.returnData[i].isDisplayed = true;
                }
                else{
                    this.returnData[i].isDisplayed = false;
                }
            }
        }

        if(this.value9 == 'Seller'){
            // Loop through the returnData array to find the correct row
            for (let i = 0; i < this.returnData.length; i++) {
                if (this.returnData[i].Seller && this.returnData[i].Seller.toLowerCase().includes(this.filterText.toLowerCase())) {
                    this.returnData[i].isDisplayed = true;
                }
                else{
                    this.returnData[i].isDisplayed = false;
                }
            }
        }

        if(this.value9 == 'Agency'){
            // Loop through the returnData array to find the correct row
            for (let i = 0; i < this.returnData.length; i++) {
                if (this.returnData[i].Agency && this.returnData[i].Agency.toLowerCase().includes(this.filterText.toLowerCase())) {
                    this.returnData[i].isDisplayed = true;
                }
                else{
                    this.returnData[i].isDisplayed = false;
                }
            }
        }

        if(this.value9 == 'Type'){
            // Loop through the returnData array to find the correct row
            for (let i = 0; i < this.returnData.length; i++) {
                if (this.returnData[i].Type && this.returnData[i].Type.toLowerCase() == this.filterText.toLowerCase()) {
                    this.returnData[i].isDisplayed = true;
                }
                else{
                    this.returnData[i].isDisplayed = false;
                }
            }
        }

        if(this.value9 == 'Channel'){
            // Loop through the returnData array to find the correct row
            for (let i = 0; i < this.returnData.length; i++) {
                if ( this.returnData[i].Channel && this.returnData[i].Channel.toLowerCase() == this.filterText.toLowerCase()) {
                    this.returnData[i].isDisplayed = true;
                }
                else{
                    this.returnData[i].isDisplayed = false;
                }
            }
        }
    }

    clearFilter() {
        this.filterText = '';
        // Loop through the returnData array to find the correct row
        for (let i = 0; i < this.returnData.length; i++) {

            this.returnData[i].isDisplayed = true;

        }
    }

    @track value9 = '';  // Selected value
    // Options for the combobox
    @track options9 = [
        { label: 'Seller', value: 'Seller' },
        { label: 'Advertiser', value: 'Advertiser' },
        { label: 'Agency', value: 'Agency' },
        { label: 'Type', value: 'Type' },
        { label: 'Channel', value: 'Channel' }
    ];

    @track filterOptions = [];
    @track displayFilterInput = true;
    // Handles changes in combobox selection
    handleChangeFilter(event) {
        this.value9 = event.detail.value;
        if(this.value9 == 'Type' || this.value9 == 'Channel'){
            this.displayFilterInput = false;
            if(this.value9 == 'Type'){
                this.filterOptions = this.options2;
            }else if(this.value9 == 'Channel'){
                this.filterOptions = this.options;
            }
        }
        else{
            this.displayFilterInput = true;
        }
    }

    
    @track filterText;

    handleFilterChange(event) {
        this.filterText = event.target.value;
        this.applyFilter();
    }


}