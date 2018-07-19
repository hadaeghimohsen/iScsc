SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[MBSP_SCHG_P]
	-- Add the parameters for the stored procedure here
	@X XML
AS
BEGIN
	/*
	   شرایط ارسال داده ها مربوط به جدول درخواست
	   1 - درخواست جدید می باشد و ستون شماره درخواست خالی می باشد
	   2 - درخواست قبلا ثبت شده و ستون شماره درخواست خالی نمی باشد
	*/
	DECLARE @ErrorMessage NVARCHAR(MAX);
	BEGIN TRAN T1;
	BEGIN TRY
	   DECLARE @Rqid     BIGINT,
	           @OrgnRqid BIGINT,
	           @RqroRwno SMALLINT,	           
   	        @FileNo BIGINT,
   	        @CbmtCode BIGINT,
   	        @CtgyCode BIGINT,
   	        @EditPymt VARCHAR(3);
   	
	   SELECT @Rqid     = @X.query('//Request').value('(Request/@rqid)[1]'    , 'BIGINT')
	         ,@RqroRwno = @X.query('//Request_Row').value('(Request_Row/@rwno)[1]', 'SMALLINT')
	         ,@FileNo   = @X.query('//Request_Row').value('(Request_Row/@fileno)[1]', 'BIGINT')
	         ,@CbmtCode = @X.query('//Member_Ship').value('(Member_Ship/@cbmtcode)[1]', 'BIGINT')
	         ,@CtgyCode = @X.query('//Member_Ship').value('(Member_Ship/@ctgycode)[1]', 'BIGINT')
	         ,@EditPymt = @X.query('//Member_Ship').value('(Member_Ship/@editpymt)[1]', 'BIGINT');
	   
	   SET @OrgnRqid = @Rqid;
	   
      DECLARE @StrtDate002 DATE
             ,@EndDate002  DATE
             ,@PrntCont002 SMALLINT
             ,@NumbMontOfer002 INT
             ,@NumbOfAttnMont002 INT
             ,@SumNumbAttnMont002 INT
             ,@AttnDayType002 VARCHAR(3);
     
     DECLARE  @StrtDate004 DATE
             ,@EndDate004  DATE
             ,@PrntCont004 SMALLINT
             ,@NumbMontOfer004 INT
             ,@NumbOfAttnMont004 INT
             ,@SumNumbAttnMont004 INT
             ,@AttnDayType004 VARCHAR(3);
      
      SELECT @StrtDate002 = STRT_DATE
            ,@EndDate002 = END_DATE
            ,@NumbOfAttnMont002 = NUMB_OF_ATTN_MONT
            ,@SumNumbAttnMont002 = SUM_ATTN_MONT_DNRM
        FROM dbo.Member_Ship
       WHERE RQRO_RQST_RQID = @Rqid
         AND RECT_CODE = '002'
         AND FIGH_FILE_NO = @FileNo;
      
      SELECT @StrtDate004 = STRT_DATE
            ,@EndDate004 = END_DATE
            ,@NumbOfAttnMont004 = NUMB_OF_ATTN_MONT
            ,@SumNumbAttnMont004 = SUM_ATTN_MONT_DNRM
        FROM dbo.Member_Ship
       WHERE RQRO_RQST_RQID = @Rqid
         AND RECT_CODE = '004'
         AND FIGH_FILE_NO = @FileNo;
      
      UPDATE dbo.Member_Ship
         SET STRT_DATE = @StrtDate004
            ,END_DATE = @EndDate004
            ,NUMB_OF_ATTN_MONT = @NumbOfAttnMont004
            ,SUM_ATTN_MONT_DNRM = @SumNumbAttnMont004
       WHERE RQRO_RQST_RQID = @Rqid
         AND RECT_CODE = '002';
      
      UPDATE dbo.Member_Ship
         SET STRT_DATE = @StrtDate002
            ,END_DATE = @EndDate002
            ,NUMB_OF_ATTN_MONT = @NumbOfAttnMont002
            ,SUM_ATTN_MONT_DNRM = @SumNumbAttnMont002
       WHERE RQRO_RQST_RQID = @Rqid
         AND RECT_CODE = '004';
      
      -- 1396/11/08 * بررسی اینکه آیا برنامه کلاسی عوض شده است یا خیر
      DECLARE @OldCbmtCode BIGINT,
              @OldCtgyCode BIGINT;
      SELECT @OldCbmtCode = fp.CBMT_CODE
            ,@OldCtgyCode = fp.CTGY_CODE
        FROM dbo.Member_Ship m, dbo.Fighter_Public fp
       WHERE m.RQRO_RQST_RQID = @Rqid
         AND m.RECT_CODE = '004'
         AND m.FGPB_RWNO_DNRM = fp.RWNO
         AND m.FGPB_RECT_CODE_DNRM = fp.RECT_CODE
         AND m.FIGH_FILE_NO = fp.FIGH_FILE_NO;
      
      IF (@CbmtCode != @OldCbmtCode) OR (@CtgyCode != @OldCtgyCode)
      BEGIN
         DECLARE @PrvnCode VARCHAR(3)
                ,@RegnCode VARCHAR(3);
         
         SELECT @PrvnCode = REGN_PRVN_CODE
               ,@RegnCode = REGN_CODE
           FROM dbo.Fighter
          WHERE FILE_NO = @FileNo;
         -- اگر تغییری در سبک و رسته ایجاد نشده باشد باید تغییر مشخصات عمومی مجزایی برای ثبت ساعت کلاسی ذخیره کنیم
         SET @X = N'<Process><Request rqstrqid="" rqtpcode="002" rqttcode="004" regncode="" prvncode="" rqstdesc="درخواست ویرایش برنامه کلاسی مشترک پیرو تمدید مشترک بخاطر عوض شدن برنامه و ساعت کلاسی و مربی"><Request_Row fileno=""></Request_Row></Request></Process>';
         SET @X.modify('replace value of (/Process/Request/@rqstrqid)[1] with sql:variable("@Rqid")');
         SET @X.modify('replace value of (/Process/Request/@regncode)[1] with sql:variable("@RegnCode")');
         SET @X.modify('replace value of (/Process/Request/@prvncode)[1] with sql:variable("@PrvnCode")');
         SET @X.modify('replace value of (/Process/Request/Request_Row/@fileno)[1] with sql:variable("@FileNo")');
         --SET @CbmtCode = @CbmtCode;
         EXEC PBL_RQST_F @X;
         
         SELECT @Rqid = MAX(R.RQID)
           FROM Request R
          WHERE R.RQST_RQID = @Rqid
            AND R.RQST_STAT = '001'
            AND R.RQTP_CODE = '002'
            AND R.RQTT_CODE = '004'
            AND CAST(R.RQST_DATE AS DATE) = CAST(GETDATE() AS DATE)
            AND r.CRET_BY = UPPER(SUSER_NAME());
         
         UPDATE dbo.Fighter_Public
            SET CBMT_CODE = @CbmtCode
               ,COCH_FILE_NO = (SELECT COCH_FILE_NO FROM dbo.Club_Method WHERE CODE = @CbmtCode)
               ,CTGY_CODE = @CtgyCode
          WHERE RQRO_RQST_RQID = @Rqid
            AND FIGH_FILE_NO = @FileNo;
         
         UPDATE dbo.Fighter
            SET CTGY_CODE_DNRM = @CtgyCode
          WHERE FILE_NO = @FileNo;
         
         SET @X = '<Process><Request rqid="" rqtpcode="002" rqttcode="004" regncode="" prvncode=""><Request_Row fileno=""></Request_Row></Request></Process>';
         SET @X.modify('replace value of (/Process/Request/@rqid)[1] with sql:variable("@Rqid")');
         SET @X.modify('replace value of (/Process/Request/@regncode)[1] with sql:variable("@RegnCode")');
         SET @X.modify('replace value of (/Process/Request/@prvncode)[1] with sql:variable("@PrvnCode")');
         SET @X.modify('replace value of (/Process/Request/Request_Row/@fileno)[1] with sql:variable("@FileNo")');
         EXEC PBL_SAVE_F @X;

         DECLARE @FgpbRwno INT
                ,@CochFileNo BIGINT;
         
         -- 1396/11/08 * بدست آوردن ردیف عمومی
         SELECT @FgpbRwno = RWNO
               ,@CochFileNo = COCH_FILE_NO
           FROM dbo.Fighter_Public
          WHERE RQRO_RQST_RQID = @Rqid
            AND RECT_CODE = '004'; 
         
         UPDATE dbo.Member_Ship
            SET FGPB_RWNO_DNRM = @FgpbRwno
          WHERE RQRO_RQST_RQID = @OrgnRqid
            AND RECT_CODE = '004';
         
         UPDATE dbo.Payment_Detail
            SET CBMT_CODE_DNRM = @CbmtCode
               ,FIGH_FILE_NO = @CochFileNo
               --,CTGY_CODE_DNRM = @CtgyCode
          WHERE PYMT_RQST_RQID = @OrgnRqid;          
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
