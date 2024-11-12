import { LightningElement } from 'lwc';
export default class ExcelFilter extends LightningElement {

    data = [
        { id: 1, name: 'John Doe', email: 'john.doe@example.com' },
        { id: 2, name: 'Jane Smith', email: 'jane.smith@example.com' },
        { id: 3, name: 'Tom Hanks', email: 'tom.hanks@example.com' },
    ];

    filterText = '';
    filteredData = this.data;

    columns = [
        { label: 'Name', fieldName: 'name' },
        { label: 'Email', fieldName: 'email' }
    ];

    handleFilterChange(event) {
        this.filterText = event.target.value.toLowerCase();
        this.applyFilter();
    }

    applyFilter() {
        if (this.filterText) {
            this.filteredData = this.data.filter(item => 
                item.name.toLowerCase().includes(this.filterText)
            );
        } else {
            this.filteredData = this.data;
        }
    }

    clearFilter() {
        this.filterText = '';
        this.filteredData = this.data;
    }

}