SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[GET_TARF_U]
(
	@FileNo BIGINT
)
RETURNS VARCHAR(11)
AS
BEGIN
   DECLARE @TarfCode VARCHAR(11);
   
	DECLARE @SexType VARCHAR(3)
	       ,@FighType VARCHAR(3)
	       ,@MtodCode BIGINT
	       ,@CtgyCode BIGINT
	       ,@ActvTag VARCHAR(3)
	       ,@DebtAmnt BIGINT
	       ,@InsrNumb VARCHAR(10)
	       ,@InsrDate DATE
	       ,@ConfStat VARCHAR(3);
	
	SELECT @SexType = SEX_TYPE_DNRM
	      ,@FighType = FGPB_TYPE_DNRM
	      ,@MtodCode = MTOD_CODE_DNRM
	      ,@CtgyCode = CTGY_CODE_DNRM
	      ,@ActvTag = ACTV_TAG_DNRM
	      ,@DebtAmnt = DEBT_DNRM
	      ,@InsrNumb = INSR_NUMB_DNRM
	      ,@InsrDate = INSR_DATE_DNRM
	      ,@ConfStat = CONF_STAT
	  FROM dbo.Fighter F
	 WHERE FILE_NO = @FileNo;
	
	IF @ConfStat = '001'
	   RETURN NULL;	   
	
	-- اولین رقم نوع جنسیت
	IF @SexType = '001'
	   SET @TarfCode = '1'
	ELSE
	   SET @TarfCode = '2';
	
	-- دومین رقم نوع هنرجو
	IF @FighType = '001'
	   SET @TarfCode += '1';
	ELSE IF @FighType = '002'
	   SET @TarfCode += '2';
   ELSE IF @FighType = '003'
	   SET @TarfCode += '3';
   ELSE IF @FighType = '005'
	   SET @TarfCode += '5';
	ELSE IF @FighType = '006'
	   SET @TarfCode += '6';
	ELSE IF @FighType = '007'
	   SET @TarfCode += '7';
   ELSE IF @FighType = '008'
	   SET @TarfCode += '8';	   
	ELSE IF @FighType = '009'
	   SET @TarfCode += '9';
   
   -- سوم و چهارمین رقم نوع سبک هنرجو
   IF @MtodCode IS NULL OR NOT EXISTS(SELECT * FROM dbo.Method WHERE CODE = @MtodCode)
      SET @TarfCode += '00'
   ELSE
      SET @TarfCode += (SELECT NATL_CODE FROM dbo.Method WHERE CODE = @MtodCode);
   
   -- پنجم و ششمین رقم نوع رسته هنرجو
   IF @CtgyCode IS NULL OR NOT EXISTS(SELECT * FROM dbo.Category_Belt WHERE Code = @CtgyCode AND MTOD_CODE = @MtodCode)
      SET @TarfCode += '00';
   ELSE
      SET @TarfCode += (SELECT NATL_CODE FROM dbo.Category_Belt WHERE Code = @CtgyCode AND MTOD_CODE = @MtodCode)
   
   -- هفتمین رقم شاخص فعالیت
   IF CAST(@ActvTag AS INT) >= 101
      SET @TarfCode += '1';
   ELSE 
      SET @TarfCode += '0';
   
   -- هشتیم رقم نوع بدهی / بستانکاری
   IF @DebtAmnt > 0
      SET @TarfCode += '1';
   ELSE IF @DebtAmnt = 0
      SET @TarfCode += '0';
   ELSE 
      SET @TarfCode += '2';
   
   -- نهمین رقم نیاز به تمدید
   SET @TarfCode += '0';
   
   -- دهمین رقم دارا بودن کارت عضویت سبک
   SET @TarfCode += '0';
   
   -- معتبر بودن کارت بیمه
   SET @TarfCode += '0';
  
      
   RETURN @TarfCode;
	   
END
GO
