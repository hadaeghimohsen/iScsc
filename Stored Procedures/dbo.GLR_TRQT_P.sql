SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GLR_TRQT_P]
	-- Add the parameters for the stored procedure here
	@X XML
AS
BEGIN
	DECLARE @AP BIT
          ,@AccessString VARCHAR(250);
   SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>184</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 184 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END

   DECLARE @ErrorMessage NVARCHAR(MAX);
   BEGIN TRY
   BEGIN TRAN T1
   
	   DECLARE @Rqid     BIGINT
	          ,@RqstRqid BIGINT
	          ,@MdulName VARCHAR(11)
	          ,@SctnName VARCHAR(11)
	          ,@PrvnCode VARCHAR(3)
	          ,@RegnCode VARCHAR(3)
	          ,@RqtpCode VARCHAR(3)
	          ,@RqttCode VARCHAR(3)
	          ,@FileNo   BIGINT
	          ,@RqroRwno SMALLINT;
  	   
  	   SELECT @RqtpCode = '020'
  	         ,@RqttCode = '004';
  	    
	   SELECT @Rqid     = @X.query('//Request').value('(Request/@rqid)[1]', 'BIGINT')
	         ,@RqstRqid     = @X.query('//Request').value('(Request/@rqstrqid)[1]', 'BIGINT')
	         ,@MdulName = @X.query('//Request').value('(Request/@mdulname)[1]', 'VARCHAR(11)')
	         ,@SctnName = @X.query('//Request').value('(Request/@sctnname)[1]', 'VARCHAR(11)')
	         ,@FileNo   = @X.query('//Request_Row').value('(Request_Row/@fighfileno)[1]', 'BIGINT');
      
      IF @FileNo = 0 OR @FileNo IS NULL BEGIN RAISERROR(N'شماره پرونده برای هنرجو وارد نشده', 16, 1); RETURN; END

      SELECT @RegnCode = Regn_Code, 
             @PrvnCode = Regn_Prvn_Code 
        FROM Fighter
       WHERE FILE_NO = @FileNo;

      -- ثبت شماره درخواست 
      IF @Rqid IS NULL OR @Rqid = 0
      BEGIN
         EXEC dbo.INS_RQST_P
            @PrvnCode,
            @RegnCode,
            @RqstRqid,
            @RqtpCode,
            @RqttCode,
            NULL,
            NULL,
            NULL,
            @Rqid OUT;  
            
         UPDATE Request
            SET MDUL_NAME = @MdulName
              ,SECT_NAME = @SctnName
          WHERE RQID = @Rqid;                
      END
      -- ثبت ردیف درخواست 
      SELECT @RqroRwno = Rwno
        FROM Request_Row
       WHERE RQST_RQID = @Rqid
         AND FIGH_FILE_NO = @FileNo;
           
      IF @RqroRwno IS NULL
      BEGIN
         EXEC INS_RQRO_P
            @Rqid
           ,@FileNo
           ,@RqroRwno OUT;
      END
      
      DECLARE @ChngType VARCHAR(3),
              @DebtType VARCHAR(3),
              @Amnt INT,
              @AgreDate DATETIME,
              @PaidDate DATETIME,
              @ChngResn VARCHAR(3),
              @ResnDesc NVARCHAR(250),
              @RqstRqidDnrm BIGINT,
              @RqroRwnoDnrm SMALLINT;
              
      SELECT @ChngType = @X.query('//Gain_Loss_Rials').value('(Gain_Loss_Rials/@chngtype)[1]', 'VARCHAR(3)')
	         ,@DebtType = @X.query('//Gain_Loss_Rials').value('(Gain_Loss_Rials/@debttype)[1]', 'VARCHAR(3)')
	         ,@Amnt     = @X.query('//Gain_Loss_Rials').value('(Gain_Loss_Rials/@amnt)[1]', 'INT')
	         --,@AgreDate = @X.query('//Gain_Loss_Rials').value('(Gain_Loss_Rials/@agredate)[1]', 'DATETIME')
	         ,@PaidDate = @X.query('//Gain_Loss_Rials').value('(Gain_Loss_Rials/@paiddate)[1]', 'DATETIME')
	         ,@ChngResn = @X.query('//Gain_Loss_Rials').value('(Gain_Loss_Rials/@chngresn)[1]', 'VARCHAR(3)')
	         ,@ResnDesc = @X.query('//Gain_Loss_Rials').value('(Gain_Loss_Rials/@resndesc)[1]', 'NVARCHAR(250)')
	         ,@RqstRqidDnrm = @X.query('//Gain_Loss_Rials').value('(Gain_Loss_Rials/@rqstrqiddnrm)[1]', 'BIGINT');
	         --,@RqroRwnoDnrm = @X.query('//Gain_Loss_Rials').value('(Gain_Loss_Rials/@rqrorwnodnrm)[1]', 'SMALLINT');
	   
	   IF LEN(@ChngType) <> 3 BEGIN RAISERROR(N'نوع تغییرات ریالی وارد نشده', 16, 1); RETURN; END
	   IF LEN(@DebtType) <> 3 BEGIN RAISERROR(N'نوع بدهی / بستانکاری وارد نشده', 16, 1); RETURN; END
	   IF LEN(@ChngResn) <> 3 BEGIN RAISERROR(N'دلیل تغییرات وارد نشده نشده', 16, 1); RETURN; END
	   IF @Amnt IS NULL OR @Amnt = 0 BEGIN RAISERROR(N'مبلغ وارد نشده', 16, 1); RETURN; END
	   --IF @PaidDate = '1900-01-01' BEGIN RAISERROR(N'تاریخ پرداخت وارد نشده نشده', 16, 1); RETURN; END
	   IF @PaidDate = '1900-01-01' BEGIN SET @PaidDate = GETDATE(); END
	   IF @ChngType = '001' AND @DebtType NOT IN ('000', '001', '002')BEGIN RAISERROR(N'تغییرات افزایش بدهی باید با حالات بدهی جاری و بدهی منجر به وصول همراه باشد. لطفا اصلاح فرمایید', 16, 1); RETURN; END
	   IF @ChngType = '002' AND @DebtType NOT IN ('003', '004', '005')BEGIN RAISERROR(N'تغییرات کاهش بدهی باید با حالات تخفیف یا تخفیف بدون بستانکاری و یا اعتبار سپرده همراه باشد. لطفا اصلاح فرمایید', 16, 1); RETURN; END
	   
	   IF @RqstRqidDnrm > 0
	      SELECT @RqroRwnoDnrm = RWNO	      
	        FROM dbo.Request_Row
	       WHERE RQST_RQID = @RqstRqidDnrm
	         AND FIGH_FILE_NO = @FileNo;
	         
      IF NOT EXISTS (
         SELECT *
           FROM dbo.Gain_Loss_Rial
          WHERE RQRO_RQST_RQID = @Rqid
            AND RQRO_RWNO = @RqroRwno
            AND FIGH_FILE_NO = @FileNo
      )
      BEGIN
         INSERT INTO dbo.Gain_Loss_Rial
                 ( GLID ,
                   RQRO_RQST_RQID ,
                   RQRO_RWNO ,
                   FIGH_FILE_NO ,
                   CONF_STAT ,
                   CHNG_TYPE ,
                   DEBT_TYPE ,
                   AMNT ,
                   PAID_DATE ,
                   CHNG_RESN ,
                   RESN_DESC ,
                   RQRO_RQST_RQID_DNRM,
                   RQRO_RWNO_DNRM
                 )
         VALUES  ( 0 , -- GLID - bigint
                   @Rqid , -- RQRO_RQST_RQID - bigint
                   @RqroRwno , -- RQRO_RWNO - smallint
                   @FileNo , -- FIGH_FILE_NO - bigint
                   '001' , -- CONF_STAT - varchar(3)
                   @ChngType , -- CHNG_TYPE - varchar(3)
                   @DebtType , -- DEBT_TYPE - varchar(3)
                   @Amnt , -- AMNT - int
                   @PaidDate , -- PAID_DATE - datetime
                   @ChngResn , -- CHNG_RESN - varchar(3)
                   @ResnDesc , -- RESN_DESC - nvarchar(250)
                   @RqstRqidDnrm,
                   @RqroRwnoDnrm
                 );
      END
      ELSE
      BEGIN
         UPDATE dbo.Gain_Loss_Rial
            SET CHNG_TYPE = @ChngType
               ,DEBT_TYPE = @DebtType
               ,AMNT = @Amnt
               ,PAID_DATE = @PaidDate
               ,CHNG_RESN = @ChngResn
               ,RESN_DESC = @ResnDesc
               ,RQRO_RQST_RQID_DNRM = @RqstRqidDnrm
               ,RQRO_RWNO_DNRM = @RqroRwnoDnrm
           WHERE RQRO_RQST_RQID = @Rqid
             AND RQRO_RWNO = @RqroRwno
             AND FIGH_FILE_NO = @FileNo;             
      END
      
      COMMIT TRAN T1
   END TRY
   BEGIN CATCH
      SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN T1;   
   END CATCH

END
GO
