SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[INS_PYDS_P]
	-- Add the parameters for the stored procedure here
	@Pymt_Cash_Code BIGINT,
	@Pymt_Rqst_Rqid BIGINT,
	@Rqro_Rwno SMALLINT,
	@Expn_Code BIGINT,
	@Amnt BIGINT,
	@Amnt_Type VARCHAR(3),
	@Stat VARCHAR(3),
	@Pyds_Desc NVARCHAR(250),
	@Advc_Code BIGINT,
	@Fgdc_Code BIGINT
AS
BEGIN
	 	-- بررسی دسترسی کاربر
	DECLARE @AP BIT
	       ,@AccessString VARCHAR(250);
	SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>179</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 179 سطوح امینتی : شما مجوز اضافه کردن تخفیف مبلغ هزینه را ندارید', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   -- پایان دسترسی
   
   IF @Amnt = 0 RAISERROR (N'مبلغ تخفیف باید مبلغی مثبت و غیر صفر باشد', 16, 1);
   IF @Rqro_Rwno = 0 OR @Rqro_Rwno IS NULL
      SET @Rqro_Rwno = 1;
   IF @Amnt_Type IS NULL
      SET @Amnt_Type = '002';
   IF @Stat IS NULL 
      SET @Stat = '002';
   
   -- 1401/07/16 * روز اعتصابات سراسری ایران و سرنگونی حکومت آخوندی ضحاک
   IF @Expn_Code IS NULL AND 
      EXISTS ( SELECT * FROM dbo.Request r WHERE r.RQID = @Pymt_Rqst_Rqid AND r.RQTP_CODE IN ('001', '009'))
      SELECT @Expn_Code = pd.EXPN_CODE
        FROM dbo.Payment_Detail pd
       WHERE pd.PYMT_RQST_RQID = @Pymt_Rqst_Rqid
         AND pd.PYMT_CASH_CODE = @Pymt_Cash_Code;
      
   INSERT INTO dbo.Payment_Discount ( PYMT_CASH_CODE ,PYMT_RQST_RQID ,RQRO_RWNO ,EXPN_CODE ,AMNT ,AMNT_TYPE ,STAT ,PYDS_DESC ,ADVC_CODE ,FGDC_CODE )
   VALUES  ( @Pymt_Cash_Code ,@Pymt_Rqst_Rqid ,@Rqro_Rwno ,@Expn_Code ,@Amnt ,@Amnt_Type ,@Stat ,@Pyds_Desc ,@Advc_Code ,@Fgdc_Code );
END
GO
