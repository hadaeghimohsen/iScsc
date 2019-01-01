SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[RouterdbCommand]
	-- Add the parameters for the stored procedure here
	/*
	   <Router_Command subsys="5" cmndcode="1" cmnddesc="خواندن اطلاعات مشتریان با شماره کدملی و موبایل">
	      <Service fileno="13971010125456564" cellphon="09033927103"/>	      
	   </Router_Command>
	*/
	@X XML
AS
BEGIN
   BEGIN TRY
   BEGIN TRAN ROTR_DBCM_T
	DECLARE @CmndCode VARCHAR(10)
	       ,@CmndDesc NVARCHAR(100);
   
   SELECT @CmndCode = @X.query('Router_Command').value('(Router_Command/@cmndcode)[1]', 'VARCHAR(10)');
   
   DECLARE @FileNo BIGINT
          ,@NatlCode VARCHAR(10)
          ,@CellPhon VARCHAR(11)
          ,@Rqid BIGINT
          ,@FngrPrnt VARCHAR(20)
          ,@FrstName NVARCHAR(250)
          ,@LastName NVARCHAR(250)
          ,@BrthDate DATE
          ,@SexType VARCHAR(3)
          ,@CbmtCode BIGINT
          ,@CtgyCode BIGINT;
   
   IF @CmndCode = '1'
   BEGIN
      SELECT @NatlCode = @X.query('//Service').value('(Service/@natlcode)[1]', 'VARCHAR(10)')
            ,@CellPhon = @X.query('//Service').value('(Service/@cellphon)[1]', 'VARCHAR(11)');
      
      -- خواندن اطلاعات مروبط به مشترکین با کدملی و شماره موبایل
      SELECT FILE_NO, NAME_DNRM, BRTH_DATE_DNRM, CELL_PHON_DNRM, NATL_CODE, FRST_NAME, LAST_NAME, SEX_TYPE,FIGH_STAT, SUNT_CODE, SUNT_DESC 
        FROM dbo.[VF$Last_Info_Fighter](NULL, NULL, NULL,@NatlCode, NULL, @CellPhon,NULL, NULL, NULL,NULL, NULL, NULL,NULL, NULL, null);      
   END
   ELSE IF @CmndCode = '2'
   BEGIN
      -- خواندن اطلاعات مربوط به برنامه های کلاسی و نرخ ها
      SELECT *
        FROM dbo.Club_Method
       WHERE MTOD_STAT = '002';
      
      SELECT *
        FROM dbo.Category_Belt
       WHERE CTGY_STAT = '002';      
   END 
   ELSE IF @CmndCode = '3'
   BEGIN
      -- برای ثبت هزینه درخواست به عنوان وصولی
      -- ابتدا مشخص شود که چه گزینه هایی برای پرداخت نیاز هست که بتوان انها را خواند و در جدول وصلی ثبت نمود
      SELECT 1;
   END 
   ELSE IF @CmndCode = '4'
   BEGIN
      -- ثبت موقت اطلاعات برای ثبت نام
      SELECT 1;
   END 
   ELSE IF @CmndCode = '5'
   BEGIN
      --  ذخیره نهایی اطلاعات ثبت نام
      SELECT 1;
   END 
   ELSE IF @CmndCode = '6'
   BEGIN
      -- ثبت موقت اطلاعات برای تمدید دوره
      SELECT 1;
   END 
   ELSE IF @CmndCode = '7'
   BEGIN
      -- ذخیره نهایی اطلاعات تمدید دوره
      SELECT 1;
   END   
  
   COMMIT TRAN ROTR_DBCM_T;
   RETURN 1;
   END TRY
   BEGIN CATCH
      DECLARE @ErrorMessage NVARCHAR(MAX);
      SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN ROTR_DBCM_T;
   END CATCH
END
GO
