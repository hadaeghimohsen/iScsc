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
   
   -- Base Variable
   DECLARE @FileNo BIGINT
          ,@NatlCode VARCHAR(10)
          ,@CellPhon VARCHAR(11)
          ,@Password VARCHAR(250)
          ,@Rqid BIGINT
          ,@FngrPrnt VARCHAR(20)
          ,@FrstName NVARCHAR(250)
          ,@LastName NVARCHAR(250)
          ,@BrthDate DATE
          ,@SexType VARCHAR(3)
          ,@CbmtCode BIGINT
          ,@CtgyCode BIGINT;
   
   -- Temp Variable
   DECLARE @Cont BIGINT;
   
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
   ELSE IF @CmndCode = '8'  
   BEGIN
      -- بررسی اینکه شماره کد ملی و رمز در سیستم مشترکین ثبت شده است یا خیر
      SELECT @NatlCode = @X.query('//Service').value('(Service/@natlcode)[1]', 'VARCHAR(10)')
            ,@Password = @X.query('//Service').value('(Service/@password)[1]', 'VARCHAR(250)');
      
      
      SELECT @Cont = COUNT(*)
        FROM dbo.Fighter f, dbo.Fighter_Public fp
       WHERE f.FILE_NO = fp.FIGH_FILE_NO
         AND f.FGPB_RWNO_DNRM = fp.RWNO
         AND fp.RECT_CODE = '004'
         AND f.NATL_CODE_DNRM = @NatlCode
         AND fp.PASS_WORD = @Password
         AND f.CONF_STAT = '002'
         AND f.ACTV_TAG_DNRM >= '101';
      
      IF @Cont = 1
      BEGIN
         SELECT 1;
      END
      ELSE
      BEGIN
         SELECT 0;
      END
   END
   ELSE IF @CmndCode = '9'
   BEGIN
      -- بازیابی اطلاعات دوره های مشتری
      SELECT @NatlCode = @X.query('//Service').value('(Service/@natlcode)[1]', 'VARCHAR(10)');
      
      SELECT ms.RWNO, ms.STRT_DATE, ms.END_DATE, ms.NUMB_OF_ATTN_MONT, ms.SUM_ATTN_MONT_DNRM, m.MTOD_DESC, cb.CTGY_DESC, c.NAME_DNRM
        FROM dbo.Fighter f, dbo.Member_Ship ms, dbo.Fighter_Public fp, dbo.Method m, dbo.Category_Belt cb, dbo.Fighter c
       WHERE f.FILE_NO = ms.FIGH_FILE_NO
         AND ms.FIGH_FILE_NO = fp.FIGH_FILE_NO
         AND ms.FGPB_RWNO_DNRM = fp.RWNO
         AND ms.FGPB_RECT_CODE_DNRM = fp.RECT_CODE
         AND ms.RECT_CODE = '004'
         AND ms.VALD_TYPE = '002'
         AND fp.MTOD_CODE = m.CODE
         AND fp.CTGY_CODE = cb.CODE
         AND fp.COCH_FILE_NO = c.FILE_NO
         AND f.NATL_CODE_DNRM = @NatlCode
         AND f.ACTV_TAG_DNRM >= '101'
         AND f.CONF_STAT = '002'
       ORDER BY ms.RWNO DESC;
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
