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
   DECLARE @AP BIT
          ,@AccessString VARCHAR(250);
   SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>233</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 233 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END;

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
             ,@AttnDayType002 VARCHAR(3)
             ,@NewFgpbRwno INT;
     
     DECLARE  @StrtDate004 DATE
             ,@EndDate004  DATE
             ,@PrntCont004 SMALLINT
             ,@NumbMontOfer004 INT
             ,@NumbOfAttnMont004 INT
             ,@SumNumbAttnMont004 INT
             ,@AttnDayType004 VARCHAR(3)
             ,@OldFgpbRwno INT;
      
      SELECT @StrtDate002 = STRT_DATE
            ,@EndDate002 = END_DATE
            ,@NumbOfAttnMont002 = NUMB_OF_ATTN_MONT
            ,@SumNumbAttnMont002 = SUM_ATTN_MONT_DNRM
            ,@NumbMontOfer002 = NUMB_MONT_OFER
        FROM dbo.Member_Ship
       WHERE RQRO_RQST_RQID = @Rqid
         AND RECT_CODE = '002'
         AND FIGH_FILE_NO = @FileNo;
      
      SELECT @StrtDate004 = STRT_DATE
            ,@EndDate004 = END_DATE
            ,@NumbOfAttnMont004 = NUMB_OF_ATTN_MONT
            ,@SumNumbAttnMont004 = SUM_ATTN_MONT_DNRM
            ,@NumbMontOfer004 = NUMB_MONT_OFER
            ,@OldFgpbRwno = FGPB_RWNO_DNRM
        FROM dbo.Member_Ship
       WHERE RQRO_RQST_RQID = @Rqid
         AND RECT_CODE = '004'
         AND FIGH_FILE_NO = @FileNo;
      
      UPDATE dbo.Member_Ship
         SET STRT_DATE = @StrtDate004
            ,END_DATE = @EndDate004
            ,NUMB_OF_ATTN_MONT = @NumbOfAttnMont004
            ,SUM_ATTN_MONT_DNRM = @SumNumbAttnMont004
            ,NUMB_MONT_OFER = @NumbMontOfer004
       WHERE RQRO_RQST_RQID = @Rqid
         AND RECT_CODE = '002';
      
      UPDATE dbo.Member_Ship
         SET STRT_DATE = @StrtDate002
            ,END_DATE = @EndDate002
            ,NUMB_OF_ATTN_MONT = @NumbOfAttnMont002
            ,SUM_ATTN_MONT_DNRM = @SumNumbAttnMont002
            ,NUMB_MONT_OFER = @NumbMontOfer002
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
         
         -- 1399/12/25 * بدست آورده شماره جدید ردیف عمومی مشتری
         SET @NewFgpbRwno = @FgpbRwno;
         
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
      
      IF EXISTS(SELECT * FROM dbo.Message_Broadcast WHERE MSGB_TYPE = '020' AND STAT = '002')        
      BEGIN
         DECLARE @MsgbStat VARCHAR(3)
                ,@MsgbText NVARCHAR(MAX)
                ,@XMsg XML                
                ,@LineType VARCHAR(3)
                ,@Cel1Phon VARCHAR(11)
                ,@Cel2Phon VARCHAR(11)
                ,@Cel3Phon VARCHAR(11)
                ,@Cel4Phon VARCHAR(11)
                ,@Cel5Phon VARCHAR(11)
                ,@AmntType VARCHAR(3)
                ,@AmntTypeDesc NVARCHAR(255);
                
         SELECT @MsgbStat = STAT
               ,@MsgbText = MSGB_TEXT
               ,@LineType = LINE_TYPE
               ,@Cel1Phon = CEL1_PHON
               ,@Cel2Phon = CEL2_PHON
               ,@Cel3Phon = CEL3_PHON
               ,@Cel4Phon = CEL4_PHON
               ,@Cel5Phon = CEL5_PHON            
           FROM dbo.Message_Broadcast
          WHERE MSGB_TYPE = '020';
         
         SELECT @MsgbText = (
            SELECT N'اصلاح دوره' + CHAR(10) +
                   rt.RQTP_DESC + CHAR(10) + 
                   N'تاریخ تایید درخواست ' + dbo.GET_MTST_U(r.SAVE_DATE) + CHAR(10) +
                   N'نام مشترک ' + f.NAME_DNRM + CHAR(10) + 
                   
                   N'اطلاعات قدیم دوره' + CHAR(10) +
                   N'تاریخ شروع : ' + dbo.GET_MTOS_U(@StrtDate004) + CHAR(10) + 
                   N'تاریخ پایان : ' + dbo.GET_MTOS_U(@EndDate004) + CHAR(10) + 
                   N'تعداد کل جلسات : ' + CAST(@NumbOfAttnMont004 AS VARCHAR(3)) + CHAR(10) + 
                   N'تعداد جلسات مصرفی : ' + CAST(@SumNumbAttnMont004 AS VARCHAR(3)) + CHAR(10) + 
                   
                   N'اطلاعات جدید دوره' + CHAR(10) +
                   N'تاریخ شروع : ' + dbo.GET_MTOS_U(@StrtDate002) + CHAR(10) + 
                   N'تاریخ پایان : ' + dbo.GET_MTOS_U(@EndDate002) + CHAR(10) + 
                   N'تعداد کل جلسات : ' + CAST(@NumbOfAttnMont002 AS VARCHAR(3)) + CHAR(10) + 
                   N'تعداد جلسات مصرفی : ' + CAST(@SumNumbAttnMont002 AS VARCHAR(3)) + CHAR(10) + 
                   
                   N'کاربر : ' + UPPER(SUSER_NAME()) + CHAR(10) + 
                   N'تاریخ : ' + dbo.GET_MTST_U(GETDATE())
              FROM dbo.Request_Type rt,
                   dbo.Request r,
                   dbo.Request_Row rr,
                   dbo.Fighter f
             WHERE r.RQID = @OrgnRqid
               AND r.RQTP_CODE = rt.CODE
               AND r.RQID = rr.RQST_RQID
               AND rr.FIGH_FILE_NO = f.FILE_NO
         );          
         
         IF @MsgbStat = '002' 
         BEGIN
            SELECT @XMsg = (
               SELECT 5 AS '@subsys',
                      @LineType AS '@linetype',
                      (
                        SELECT @Cel1Phon AS '@phonnumb',
                               (
                                   SELECT '020' AS '@type' 
                                          ,@MsgbText
                                      FOR XML PATH('Message'), TYPE 
                               ) 
                           FOR XML PATH('Contact'), TYPE
                      ),
                      (
                        SELECT @Cel2Phon AS '@phonnumb',
                               (
                                   SELECT '020' AS '@type' 
                                          ,@MsgbText
                                      FOR XML PATH('Message'), TYPE 
                               ) 
                           FOR XML PATH('Contact'), TYPE
                      ),
                      (
                        SELECT @Cel3Phon AS '@phonnumb',
                               (
                                   SELECT '020' AS '@type' 
                                          ,@MsgbText
                                      FOR XML PATH('Message'), TYPE 
                               ) 
                           FOR XML PATH('Contact'), TYPE
                      ),
                      (
                        SELECT @Cel4Phon AS '@phonnumb',
                               (
                                   SELECT '020' AS '@type' 
                                          ,@MsgbText
                                      FOR XML PATH('Message'), TYPE 
                               ) 
                           FOR XML PATH('Contact'), TYPE
                      ),
                      (
                        SELECT @Cel5Phon AS '@phonnumb',
                               (
                                   SELECT '020' AS '@type' 
                                          ,@MsgbText
                                      FOR XML PATH('Message'), TYPE 
                               ) 
                           FOR XML PATH('Contact'), TYPE
                      )                   
                 FOR XML PATH('Contacts'), ROOT('Process')                            
            );
            EXEC dbo.MSG_SEND_P @X = @XMsg -- xml                  
         END;
      END 
      
      -- ثبت درخواست اصلاح دوره در سابقه مشتری
      -- 1399/12/29 * ثبت درخواست
      DECLARE @RqtpCode VARCHAR(3) = '034',
              @RqttCode VARCHAR(3) = '004',
              @LettNo  VARCHAR(15) = @Rqid,
              @LettDate DATETIME = GETDATE(),
              @LettOwnr VARCHAR(250) = UPPER(SUSER_NAME());
      
      SELECT @PrvnCode = REGN_PRVN_CODE
            ,@RegnCode = REGN_CODE
        FROM dbo.Fighter
       WHERE FILE_NO = @FileNo;
              
      EXEC dbo.INS_RQST_P
         @PrvnCode,
         @RegnCode,
         @Rqid,
         @RqtpCode,
         @RqttCode,
         @LettNo,
         @LettDate,
         @LettOwnr,
         @Rqid OUT; 
         
      UPDATE dbo.Request
         SET MDUL_NAME = 'MBSP_CHNG_F'
            ,SECT_NAME = 'MBSP_CHNG_F'            
       WHERE RQID = @Rqid;
      
      EXEC INS_RQRO_P
         @Rqid
        ,@FileNo
        ,@RqroRwno OUT;
      
      -- چیزی که بوده
      EXEC INS_MBSP_P @Rqid, @RqroRwno, @FileNo, '001', '001', @StrtDate004, @EndDate004, 0, @NumbMontOfer004, @NumbOfAttnMont004, 0, @AttnDayType004;
      UPDATE dbo.Member_Ship
         SET FGPB_RWNO_DNRM = @OldFgpbRwno
            ,FGPB_RECT_CODE_DNRM = '004'
       WHERE RQRO_RQST_RQID = @Rqid;
       
      -- چیزی که شده
      EXEC INS_MBSP_P @Rqid, @RqroRwno, @FileNo, '002', '001', @StrtDate002, @EndDate002, 0, @NumbMontOfer002, @NumbOfAttnMont002, 0, @AttnDayType002;
      UPDATE dbo.Member_Ship
         SET FGPB_RWNO_DNRM = ISNULL(@NewFgpbRwno, @OldFgpbRwno)
            ,FGPB_RECT_CODE_DNRM = '004'
       WHERE RQRO_RQST_RQID = @Rqid;
      
      UPDATE Request
         SET RQST_STAT = '002'
       WHERE RQID = @Rqid;
               
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
