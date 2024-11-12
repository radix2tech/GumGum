public with sharing class AttachPDF {
	public AttachPDF(ApexPages.StandardController controller) {}


	public PageReference CreateAttachment(){
		PageReference pdf = Page.SystemSnapshotPDF;
		pdf.getParameters().put('id',ApexPages.CurrentPage().getParameters().get('id'));
		Attachment attach = new Attachment();
		Blob body = pdf.getContent();
		attach.Body = body;
		attach.Name = 'System_Information.pdf';
    	attach.ParentId = ApexPages.CurrentPage().getParameters().get('id');
    	insert attach;
    	Pagereference MyPage = new Pagereference('/'+ApexPages.CurrentPage().getParameters().get('id'));
		MyPage.setRedirect(true);
		return MyPage;
	}

}