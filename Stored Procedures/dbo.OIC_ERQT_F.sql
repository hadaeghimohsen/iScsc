SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[OIC_ERQT_F]
	-- Add the parameters for the stored procedure here
	@X XML
AS
BEGIN
   DECLARE @AP BIT
          ,@AccessString VARCHAR(250);
   SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>151</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 151 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END

   SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>152</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 152 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   
	DECLARE @ErrorMessage NVARCHAR(MAX);
	BEGIN TRAN T1;
	BEGIN TRY
	   DECLARE @Rqid     BIGINT,
	           @RqstRqid BIGINT,
	           @RqtpCode VARCHAR(3),
	           @RqttCode VARCHAR(3),
	           @LettNo   VARCHAR(15),
	           @LettDate DATETIME,
	           @LettOwnr NVARCHAR(250),
	           @RqstDesc NVARCHAR(1000),
	           
	           @RegnCode VARCHAR(3),
	           @PrvnCode VARCHAR(3),
	           @CntyCode VARCHAR(3),
	           
  	           @MdulName VARCHAR(11),
	           @SctnName VARCHAR(11),
	           
	           @RefSubSys INT,
	           @RefCode BIGINT;
   	
   	DECLARE @FileNo BIGINT
   	       ,@FrstName NVARCHAR(250)
   	       ,@LastName NVARCHAR(250)
   	       ,@NatlCode VARCHAR(10)
   	       ,@CellPhon VARCHAR(11)
   	       ,@SuntCode VARCHAR(4)
   	       ,@ServNo NVARCHAR(50);
   	       
	   SELECT @Rqid     = @X.query('//Request').value('(Request/@rqid)[1]'    , 'BIGINT')
	         ,@RqstRqid = @X.query('//Request').value('(Request/@rqstrqid)[1]'    , 'BIGINT')
	         ,@RqtpCode = @X.query('//Request').value('(Request/@rqtpcode)[1]', 'VARCHAR(3)')
	         ,@RqttCode = @X.query('//Request').value('(Request/@rqttcode)[1]', 'VARCHAR(3)')
	         ,@LettNo   = @X.query('//Request').value('(Request/@lettno)[1]', 'VARCHAR(15)')
	         ,@LettDate   = @X.query('//Request').value('(Request/@lettdate)[1]', 'DATETIME')
	         ,@LettOwnr   = @X.query('//Request').value('(Request/@lettownr)[1]', 'NVARCHAR(250)')
	         ,@RqstDesc = @X.query('//Request').value('(Request/@rqstdesc)[1]', 'NVARCHAR(1000)')
	         
	         
	         ,@MdulName = @X.query('//Request').value('(Request/@mdulname)[1]', 'VARCHAR(11)')
	         ,@SctnName = @X.query('//Request').value('(Request/@sctnname)[1]', 'VARCHAR(11)')
	         
	         ,@RefSubSys = @X.query('//Request').value('(Request/@refsubsys)[1]', 'INT')
	         ,@RefCode   = @X.query('//Request').value('(Request/@refcode)[1]', 'BIGINT')
	         
	         ,@FileNo   = @X.query('//Request_Row').value('(Request_Row/@fileno)[1]', 'BIGINT')
	         
	         ,@FrstName = @X.query('//Fighter_Public').value('(Fighter_Public/@frstname)[1]', 'NVARCHAR(250)')
	         ,@LastName = @X.query('//Fighter_Public').value('(Fighter_Public/@lastname)[1]', 'NVARCHAR(250)')
	         ,@NatlCode = @X.query('//Fighter_Public').value('(Fighter_Public/@natlcode)[1]', 'VARCHAR(10)')
	         ,@CellPhon = @X.query('//Fighter_Public').value('(Fighter_Public/@cellphon)[1]', 'VARCHAR(11)')
	         ,@SuntCode = @X.query('//Fighter_Public').value('(Fighter_Public/@suntcode)[1]', 'VARCHAR(4)')
	         ,@ServNo   = @X.query('//Fighter_Public').value('(Fighter_Public/@servno)[1]', 'NVARCHAR(50)');
      
      IF @FileNo = 0 OR @FileNo IS NULL 
         SELECT TOP 1 @FileNo = FILE_NO
           FROM dbo.Fighter f, dbo.Club_Method cm
          WHERE f.CBMT_CODE_DNRM = cm.CODE
            AND convert(varchar(10), GETDATE(), 108) BETWEEN convert(varchar(10), STRT_TIME, 108) AND convert(varchar(10), END_TIME, 108)
            AND cm.CLUB_CODE IN (SELECT CLUB_CODE FROM dbo.V#UCFGA WHERE Sys_User = SUSER_NAME())
            AND f.FGPB_TYPE_DNRM = '005';
         
      IF @FileNo = 0 OR @FileNo IS NULL BEGIN RAISERROR(N'شماره پرونده برای هنرجو وارد نشده', 16, 1); RETURN; END
      IF LEN(@RqttCode) <> 3 BEGIN RAISERROR(N'نوع متقاضی برای درخواست وارد نشده', 16, 1); RETURN; END      
      IF @RqstRqid = 0 SET @RqstRqid = NULL;
      
      SELECT @RegnCode = Regn_Code, @PrvnCode = Regn_Prvn_Code , @CntyCode = REGN_PRVN_CNTY_CODE
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
            @LettNo,
            @LettDate,
            @LettOwnr,
            @Rqid OUT; 

         UPDATE Request
            SET MDUL_NAME = @MdulName
               ,SECT_NAME = @SctnName
               ,REF_SUB_SYS = @RefSubSys
               ,REF_CODE = @RefCode
               ,RQST_DESC = @RqstDesc               
          WHERE RQID = @Rqid;                
     
      END
      ELSE 
      BEGIN      
         UPDATE Request
            SET RQST_DESC = @RqstDesc
               ,LETT_NO = @LettNo
               ,LETT_DATE = @LettDate
          WHERE RQID = @Rqid;                
      END;


      -- ثبت ردیف درخواست 
      DECLARE @RqroRwno SMALLINT;
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
      
      
      
      -- 1396/08/08 * اگر هزینه برای مشترک آزاد ثبت میشود می توانیم اطلاعات مشتری را ثبت کنیم
      BEGIN
         IF EXISTS(SELECT * FROM dbo.Fighter WHERE FILE_NO = @FileNo AND FGPB_TYPE_DNRM = '005')
         BEGIN
            IF @SuntCode IS NULL OR @SuntCode = ''
               SET @SuntCode = '0000';
               
            IF NOT EXISTS(SELECT * FROM dbo.Fighter_Public WHERE RQRO_RQST_RQID = @Rqid AND FIGH_FILE_NO = @FileNo)
               INSERT INTO dbo.Fighter_Public (REGN_PRVN_CNTY_CODE, REGN_PRVN_CODE, REGN_CODE, RQRO_RQST_RQID, RQRO_RWNO, FIGH_FILE_NO, RECT_CODE, FRST_NAME, LAST_NAME, NATL_CODE, CELL_PHON, CLUB_CODE, CBMT_CODE, MTOD_CODE, CTGY_CODE, [TYPE])
               Select @CntyCode, @PrvnCode, @RegnCode, @Rqid, 1, @FileNo, '001', ISNULL(@FrstName, ''), ISNULL(@LastName, ''), @NatlCode, @CellPhon, CLUB_CODE_DNRM, CBMT_CODE_DNRM, MTOD_CODE_DNRM, CTGY_CODE_DNRM, FGPB_TYPE_DNRM
                 FROM dbo.Fighter
                WHERE FILE_NO = @FileNo;
            ELSE
               UPDATE dbo.Fighter_Public
                  SET
                     FRST_NAME = ISNULL(@FrstName, '')
                    ,LAST_NAME = ISNULL(@LastName, '')
                    ,CELL_PHON = @CellPhon
                    ,NATL_CODE = @NatlCode
                    ,SUNT_BUNT_DEPT_ORGN_CODE = '00'
                    ,SUNT_BUNT_DEPT_CODE = '00'
                    ,SUNT_BUNT_CODE = '00'
                    ,SUNT_CODE = @SuntCode
                    ,SERV_NO = @ServNo
                WHERE RQRO_RQST_RQID = @Rqid
                  AND FIGH_FILE_NO = @FileNo
                  AND RECT_CODE = '001';
         END
         ELSE
         BEGIN
            DELETE dbo.Fighter_Public
             WHERE RQRO_RQST_RQID = @Rqid
               AND RECT_CODE = '001';
         END      
      END
      
      BEGIN                
      -- اگر در ثبت موقت باشیم و برای نوع درخواست و متقاضی آیین نامه هزینه داری داشته باشیم درخواست را به فرم اعلام هزینه ارسال میکنیم            
      IF EXISTS(
         SELECT *
           FROM Request_Row Rr, Fighter F
          WHERE Rr.FIGH_FILE_NO = F.FILE_NO
            AND Rr.RQST_RQID = @Rqid
            AND EXISTS(
               SELECT *
                 FROM dbo.VF$All_Expense_Detail(
                  @PrvnCode, 
                  @RegnCode, 
                  NULL, 
                  @RqtpCode, 
                  @RqttCode, 
                  NULL, 
                  NULL, 
                  NULL , 
                  NULL)
            )
      )
      BEGIN
         IF NOT EXISTS(SELECT * FROM Request WHERE RQID = @Rqid AND SSTT_MSTT_CODE = 2 AND SSTT_CODE = 2)
         BEGIN
            SELECT @X = (
               SELECT @Rqid '@rqid'          
                     ,@RqtpCode '@rqtpcode'
                     ,@RqttCode '@rqttcode'
                     ,@RegnCode '@regncode'  
                     ,@PrvnCode '@prvncode'
               FOR XML PATH('Request'), ROOT('Process')
            );
            EXEC INS_SEXP_P @X;             

            UPDATE Request
               SET SEND_EXPN = '002'
                  ,SSTT_MSTT_CODE = 2
                  ,SSTT_CODE = 2
             WHERE RQID = @Rqid;
        END
      END
      ELSE
      BEGIN
         UPDATE Request
            SET SEND_EXPN = '001'
               ,SSTT_MSTT_CODE = 1
               ,SSTT_CODE = 1
          WHERE RQID = @Rqid;                
         
         DELETE Payment_Detail 
          WHERE PYMT_RQST_RQID = @Rqid;          
         DELETE dbo.Payment_Discount
          WHERE PYMT_RQST_RQID = @Rqid;
         DELETE Payment
          WHERE RQST_RQID = @Rqid;            
      END  
      END      
      COMMIT TRAN T1;
   END TRY
   BEGIN CATCH
      SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN T1;
   END CATCH;   
END
GO
