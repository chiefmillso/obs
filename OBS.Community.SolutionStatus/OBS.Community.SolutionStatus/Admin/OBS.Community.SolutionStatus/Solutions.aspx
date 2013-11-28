<%@ Assembly Name="$SharePoint.Project.AssemblyFullName$" %>
<%@ Assembly Name="Microsoft.SharePoint.ApplicationPages.Administration, Version=14.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c"%> 
<%@ Page Language="C#" Inherits="Microsoft.SharePoint.ApplicationPages.OperationsPage" MasterPageFile="~/_admin/admin.master" %> 
<%@ Import Namespace="Microsoft.SharePoint.ApplicationPages" %> <%@ Register Tagprefix="SharePoint" Namespace="Microsoft.SharePoint.WebControls" Assembly="Microsoft.SharePoint, Version=14.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c" %> 
<%@ Register Tagprefix="Utilities" Namespace="Microsoft.SharePoint.Utilities" Assembly="Microsoft.SharePoint, Version=14.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c" %> 
<%@ Import Namespace="Microsoft.SharePoint" %> 
<%@ Assembly Name="Microsoft.Web.CommandUI, Version=14.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c" %>
<%@ Register Tagprefix="SharePoint" Namespace="Microsoft.SharePoint.WebControls" Assembly="Microsoft.SharePoint, Version=14.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c" %> <%@ Register Tagprefix="Utilities" Namespace="Microsoft.SharePoint.Utilities" Assembly="Microsoft.SharePoint, Version=14.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c" %> <%@ Import Namespace="Microsoft.SharePoint" %> <%@ Assembly Name="Microsoft.Web.CommandUI, Version=14.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c" %> <%@ Register Tagprefix="wssawc" Namespace="Microsoft.SharePoint.WebControls" Assembly="Microsoft.SharePoint, Version=14.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c" %> <%@ Register Tagprefix="SharePoint" Namespace="Microsoft.SharePoint.WebControls" Assembly="Microsoft.SharePoint, Version=14.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c" %> <%@ Register Tagprefix="AdminControls" Namespace="Microsoft.SharePoint.WebControls" Assembly="Microsoft.SharePoint.ApplicationPages.Administration" %>
<asp:content ID="Content1" contentplaceholderid="PlaceHolderPageTitle" runat="server">
	<SharePoint:EncodedLiteral ID="EncodedLiteral1" runat="server" text="<%$Resources:spadmin, solutions_PageTitle%>" EncodeMethod='HtmlEncode'/>
</asp:content>
<asp:content ID="Content2" contentplaceholderid="PlaceHolderPageTitleInTitleArea" runat="server">
	<SharePoint:EncodedLiteral ID="EncodedLiteral2" runat="server" text="<%$Resources:spadmin, solutions_PageTitle%>" EncodeMethod='HtmlEncode'/>
</asp:content>
<asp:content ID="Content3" contentplaceholderid="PlaceHolderPageDescription" runat="server">
	<SharePoint:EncodedLiteral ID="EncodedLiteral3" runat="server" text="<%$Resources:spadmin, solutions_PageDescription%>" EncodeMethod='HtmlEncodeAllowSimpleTextFormatting'/>
</asp:content>
<asp:content ID="Content4" contentplaceholderid="PlaceHolderMain" runat="server">
<script src="jquery-1.10.2.min.js" type="text/javascript" ></script>
<script type="text/javascript">
    function Retrieve(solutionId, obj) {
        var anchor = $(obj);
        $.get('SolutionStatus.ashx?solutionId=' + solutionId, function (data) {
            if (data.Error) {
                anchor.attr('error', data.ErrorMessage);
            }
            else {
                anchor.parent().html(data.Version);
            }
        });
    }

    $(document).ready(function () {
        $("#SolutionsGrid a.retrieve").each(function (index, el) {
            $(el).click();
        });
    });
</script>
<table width="100%" class="propertysheet" cellspacing="0" cellpadding="0" border="0"> <tr> <td class="ms-descriptionText"> <asp:Label ID="LabelMessage" Runat="server" EnableViewState="False" class="ms-descriptionText"/> </td> </tr> <tr> <td class="ms-error"><asp:Label ID="LabelErrorMessage" Runat="server" EnableViewState="False" /></td> </tr> <tr> <td class="ms-descriptionText"> <asp:ValidationSummary ID="ValSummary" HeaderText="<%$SPHtmlEncodedResources:spadmin, ValidationSummaryHeaderText%>" DisplayMode="BulletList" ShowSummary="True" runat="server"> </asp:ValidationSummary> </td> </tr> </table>
<table border="0" cellspacing="4" cellpadding="0" width="100%">
	<tr>
		<td id="SolutionsGrid">
			<AdminControls:AdministrationDataSourceControl runat="server" ID="SolutionsDS" ViewName="Solutions" />
			<SharePoint:SPGridView
				id="GvItems"
				runat="server"
				AutoGenerateColumns="false"
				width="100%"
				AllowSorting="True"
				DataSourceId="SolutionsDS" >
				<AlternatingRowStyle CssClass="ms-alternatingstrong" />
				<EmptyDataTemplate>
				   <SharePoint:EncodedLiteral ID="EncodedLiteral4" runat="server" text="<%$Resources:spadmin, solutions_empty1%>" EncodeMethod='HtmlEncode'/>
				   <br /><br />
				   <SharePoint:EncodedLiteral ID="EncodedLiteral5" runat="server" text="<%$Resources:spadmin, solutions_empty2%>" EncodeMethod='HtmlEncode'/>
				   <br /><br />
				   <SharePoint:EncodedLiteral ID="EncodedLiteral6" runat="server" text="<%$Resources:spadmin, solutions_empty3%>" EncodeMethod='HtmlEncode'/>
				</EmptyDataTemplate>
				<Columns>
					<asp:TemplateField
						SortExpression="ItemName"
						HeaderText="<%$SPHtmlEncodedResources:spadmin, solutions_Name%>">
						<ItemStyle VerticalAlign="Top" />
						<ItemTemplate>
							<%# @"<a href='" + SPHttpUtility.HtmlUrlAttributeEncode(Eval("SolutionLink").ToString()) + "'>" + SPHttpUtility.HtmlEncode(Eval("ItemName").ToString()) + @"</a>" %>
						</ItemTemplate>
					</asp:TemplateField>
                    <asp:TemplateField
                        HeaderText="Version">
                        <ItemStyle VerticalAlign="Top" />
                        <ItemTemplate>
                            <a class="retrieve" href="#" onclick="Retrieve('<%# Eval("ItemName") %>', this)">Retrieve</a>
                        </ItemTemplate>    
                    </asp:TemplateField>
                    <asp:TemplateField
                        HeaderText="Download">
                        <ItemStyle VerticalAlign="Top" />
                        <ItemTemplate>
                            <a class="download" href="SolutionStatus.ashx?operation=download&solutionId=<%# Eval("ItemName") %>">Download</a>
                        </ItemTemplate>    
                    </asp:TemplateField>
					<asp:BoundField
						HeaderText="<%$Resources:spadmin, solutions_Status%>"
						HtmlEncode="false"
						SortExpression="Status"
						DataField="HtmlStatus" />
					<asp:BoundField
						HeaderText="<%$Resources:spadmin, solutions_Deployed%>"
						HtmlEncode="true"
					DataField="Deployed" />
				</Columns>
			</SharePoint:SPGridView>
		</td>
	</tr>
</table>
</asp:content>
