SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[GOTO_NEXT_F]
(
	@X XML
)
RETURNS XML
AS
BEGIN
   --'<Process><Request rqid="13931006113547010" rqtpcode="001" rqttcode="001" msttcode="1" ssttcode="1"/></Process>'
	DECLARE @Rqid BIGINT
	       ,@RqtpCode VARCHAR(3)
	       ,@RqttCode VARCHAR(3)
	       ,@MsttCode SMALLINT
	       ,@SsttCode SMALLINT
	       ,@CrntForm SMALLINT;
	
	SELECT @Rqid     = @X.query('//Request').value('(Request/@rqid)[1]', 'BIGINT')
	      ,@RqtpCode = @X.query('//Request').value('(Request/@rqtpcode)[1]', 'VARCHAR(3)')
	      ,@RqttCode = @X.query('//Request').value('(Request/@rqttcode)[1]', 'VARCHAR(3)')
	      ,@CrntForm = @X.query('//Form').value('(Form/@mtodnumb)[1]', 'SMALLINT');
	
	SELECT @MsttCode = SSTT_MSTT_CODE,
	       @SsttCode = SSTT_CODE			
	  FROM Request
	 WHERE RQID = @Rqid;
	
	DECLARE @Respons XML;
	SET @Respons = '<Respons><Request rqid=""/></Respons>';
	SET @Respons.modify(
	   'replace value of (//Request/@rqid)[1]
	    with sql:variable("@Rqid")'
	);
	
	IF @RqtpCode = '001'
	BEGIN
	   -- ثبت موقت ثبت نام
	   IF @MsttCode = 1 AND @SsttCode = 1
	   BEGIN
	      -- اگر فرم ثبت اطلاعات تکمیلی باشیم نباید به فرم بعدی برویم
	      IF @CrntForm = 16
	      BEGIN
	         SET @Respons.modify(
	            'insert <NextForm mtodnumb="-1" mtoddesc=""/>
	             into (/Respons/Request)[1]'
	         )
	         GOTO End_Func;
	      END
	      IF @CrntForm = 17
	      BEGIN
	         SET @Respons.modify(
	            'insert <NextForm mtodnumb="-1" mtoddesc=""/>
	             into (/Respons/Request)[1]'
	         )
	         GOTO End_Func;
	      END
	      IF EXISTS(
	         SELECT *
	           FROM Fighter F, Fighter_Public P, Category_Belt C
	          WHERE F.FILE_NO = P.FIGH_FILE_NO
	            AND P.CTGY_CODE = C.CODE
	            AND C.ORDR <> 0
	            AND F.RQST_RQID = @Rqid
	            AND P.RECT_CODE = '001'	           
	      )
	         SET @Respons.modify(
	            'insert <NextForm mtodnumb="16" mtoddesc="ADM_FSUM_F"/>
	             into (/Respons/Request)[1]'
	         )
	      ELSE
	         -- اگر برای درخواست اعلام هزینه باید انجام بشود
	         IF EXISTS(
	            SELECT *
	              FROM Request
	             WHERE RQID = @Rqid
	               AND SEND_EXPN = '002'
	         )
	            SET @Respons.modify(
	               'insert <NextForm mtodnumb="17" mtoddesc="ADM_SEXP_F"/>
	                into (/Respons/Request)[1]'
	            )
	         ELSE
	            SET @Respons.modify(
	               'insert <NextForm mtodnumb="19" mtoddesc="ADM_SAVE_F"/>
	                into (/Respons/Request)[1]'
	            )
	   END -- @MsttCode = 1 AND @SsttCode = 1	  
	   -- ثبت اطلاعات تکمیلی
	   ELSE IF @MsttCode = 4 AND @SsttCode = 1
	   BEGIN
	      -- اگر برای درخواست اعلام هزینه باید انجام بشود
	         IF EXISTS(
	            SELECT *
	              FROM Request
	             WHERE RQID = @Rqid
	               AND SEND_EXPN = '002'
	         )
	         BEGIN
	            -- اگر در فرم اعلام هزینه باشیم
	            IF @CrntForm = 17
	            BEGIN
	               SET @Respons.modify(
	                  'insert <NextForm mtodnumb="-1" mtoddesc=""/>
	                   into (/Respons/Request)[1]'
	               )
	               GOTO End_Func;
	            END
	            SET @Respons.modify(
	               'insert <NextForm mtodnumb="17" mtoddesc="ADM_SEXP_F"/>
	                into (/Respons/Request)[1]'
	            )
	         END
	         ELSE
	         BEGIN
	            -- اگر در فرم ذخیره نهایی نباشیم
	            IF @CrntForm = 19
	            BEGIN
	               SET @Respons.modify(
	                  'insert <NextForm mtodnumb="-1" mtoddesc=""/>
	                   into (/Respons/Request)[1]'
	               )
	               GOTO End_Func;
	            END
	            SET @Respons.modify(
	               'insert <NextForm mtodnumb="19" mtoddesc="ADM_SAVE_F"/>
	                into (/Respons/Request)[1]'
	            )
	         END
	   END -- @MsttCode = 4 AND @SsttCode = 1
	   ELSE IF @MsttCode = 2 AND @SsttCode = 2
	   BEGIN
	      -- اگر در فرم تایید پرداخت باشیم
	      IF @CrntForm = 18
         BEGIN
            SET @Respons.modify(
               'insert <NextForm mtodnumb="-1" mtoddesc=""/>
                into (/Respons/Request)[1]'
            )
            GOTO End_Func;
         END
	      SET @Respons.modify(
            'insert <NextForm mtodnumb="18" mtoddesc="ADM_REXP_F"/>
             into (/Respons/Request)[1]'
         )
	   END -- @MsttCode = 2 AND @SsttCode = 2
	   ELSE IF @MsttCode = 3 AND @SsttCode = 1
	   BEGIN
	      -- اگر در فرم ذخیره نهایی باشیم
	      IF @CrntForm = 19
         BEGIN
            SET @Respons.modify(
               'insert <NextForm mtodnumb="-1" mtoddesc=""/>
                into (/Respons/Request)[1]'
            )
            GOTO End_Func;
         END
	      SET @Respons.modify(
            'insert <NextForm mtodnumb="19" mtoddesc="ADM_SAVE_F"/>
             into (/Respons/Request)[1]'
         )
	   END -- @MsttCode = 3 AND @SsttCode = 1
  	   ELSE IF EXISTS(
  	      SELECT *
           FROM Request
          WHERE RQID = @Rqid
            AND SEND_EXPN = '002'
  	   )
	   BEGIN
	      IF @CrntForm = 17
	      BEGIN
	         SET @Respons.modify(
	            'insert <NextForm mtodnumb="-1" mtoddesc=""/>
	             into (/Respons/Request)[1]'
	         )
	         GOTO End_Func;
	      END
	   END

	END -- @RqtpCode = '001'
		/********************************
	*********************************
	*********************************/	
	ELSE IF @RqtpCode = '002'
	BEGIN
	   -- ثبت موقت
	   IF @MsttCode = 1 AND @SsttCode = 1
	   BEGIN	
	      IF EXISTS(
	         SELECT *
   	        FROM Request R, Request_Row Rr, Fighter F, Fighter_Public P1, Fighter_Public P2
   	       WHERE R.RQID           = Rr.RQST_RQID
   	         AND Rr.FIGH_FILE_NO  = F.FILE_NO
   	         AND Rr.RECD_STAT     = '002'
   	         AND R.RQID           = @Rqid
   	         AND P1.FIGH_FILE_NO  = F.FILE_NO
   	         AND P1.RWNO          = F.FGPB_RWNO_DNRM
   	         AND P1.RECT_CODE     = '004'   	         
   	         AND P2.RQRO_RQST_RQID = R.RQID
   	         AND P2.RQRO_RWNO      = Rr.RWNO
   	         AND P2.RECT_CODE      = '001'
   	         AND ISNULL(P1.DISE_CODE, 0)      = ISNULL(P2.DISE_CODE, 0)
               AND ISNULL(P1.CLUB_CODE, 0)      = ISNULL(P2.CLUB_CODE, 0)
               AND ISNULL(P1.FRST_NAME, '')     = ISNULL(P2.FRST_NAME, '')
               AND ISNULL(P1.LAST_NAME, '')     = ISNULL(P2.LAST_NAME, '')
               AND ISNULL(P1.FATH_NAME, '')     = ISNULL(P2.FATH_NAME, '')
               AND ISNULL(P1.SEX_TYPE, '')      = ISNULL(P2.SEX_TYPE, '')
               AND ISNULL(P1.NATL_CODE, 0)      = ISNULL(P2.NATL_CODE, 0)
               AND ISNULL(P1.BRTH_DATE, GETDATE()) = ISNULL(P2.BRTH_DATE, GETDATE())
               AND ISNULL(P1.CELL_PHON, '')     = ISNULL(P2.CELL_PHON, '')
               AND ISNULL(P1.TELL_PHON, '')     = ISNULL(P2.TELL_PHON, '')
               AND ISNULL(P1.COCH_DEG, '')      = ISNULL(P2.COCH_DEG, '')
               AND ISNULL(P1.GUDG_DEG, '')      = ISNULL(P2.GUDG_DEG, '')
               AND ISNULL(P1.TYPE, '')          = ISNULL(P2.TYPE, '')
               AND ISNULL(P1.POST_ADRS, '')     = ISNULL(P2.POST_ADRS, '')
               AND ISNULL(P1.EMAL_ADRS, '')     = ISNULL(P2.EMAL_ADRS, '')
               AND ISNULL(P1.INSR_NUMB, '')     = ISNULL(P2.INSR_NUMB, '')
               AND ISNULL(P1.INSR_DATE, GETDATE()) = ISNULL(P2.INSR_DATE, GETDATE())   	         
	      )      
	      BEGIN
	         SET @Respons.modify(
	               'insert <NextForm mtodnumb="-1" mtoddesc=""/>
	                into (/Respons/Request)[1]'
	            )
	         GOTO End_Func;
	      END
	         
         -- اگر برای درخواست اعلام هزینه باید انجام بشود         
         IF EXISTS(
            SELECT *
              FROM Request
             WHERE RQID = @Rqid
               AND SEND_EXPN = '002'
         )
            SET @Respons.modify(
               'insert <NextForm mtodnumb="48" mtoddesc="PBL_SEXP_F"/>
                into (/Respons/Request)[1]'
            )
         ELSE
            SET @Respons.modify(
               'insert <NextForm mtodnumb="50" mtoddesc="PBL_SAVE_F"/>
                into (/Respons/Request)[1]'
            )
	   END -- @MsttCode = 1 AND @SsttCode = 1	   
	   ELSE IF @MsttCode = 2 AND @SsttCode = 1
	   BEGIN
	      SET @Respons.modify(
	            'insert <NextForm mtodnumb="-1" mtoddesc=""/>
	             into (/Respons/Request)[1]'
	         )
	      GOTO End_Func;
	   END -- @MsttCode = 2 AND @SsttCode = 1
	   ELSE IF @MsttCode = 2 AND @SsttCode = 2
	   BEGIN
	      -- فرم تاييد پرداخت
	      IF @CrntForm = 49
	      BEGIN
	         SET @Respons.modify(
	            'insert <NextForm mtodnumb="-1" mtoddesc=""/>
	             into (/Respons/Request)[1]'
	         )
	         GOTO End_Func;
	      END
	      SET @Respons.modify(
            'insert <NextForm mtodnumb="49" mtoddesc="PBL_REXP_F"/>
             into (/Respons/Request)[1]'
         )
	   END
	   ELSE IF @MsttCode = 3 AND @SsttCode = 1
	   BEGIN
	      -- فرم تاييد پرداخت
	      SET @Respons.modify(
            'insert <NextForm mtodnumb="50" mtoddesc="PBL_SAVE_F"/>
             into (/Respons/Request)[1]'
         )
	   END
	END -- @RqtpCode = '002'
	/********************************
	*********************************
	*********************************/	
	ELSE IF @RqtpCode = '003'
	BEGIN
	   -- ثبت موقت
	   IF @MsttCode = 1 AND @SsttCode = 1
	   BEGIN	      
         -- اگر برای درخواست اعلام هزینه باید انجام بشود
         IF EXISTS(
            SELECT *
              FROM Request
             WHERE RQID = @Rqid
               AND SEND_EXPN = '002'
         )
            SET @Respons.modify(
               'insert <NextForm mtodnumb="34" mtoddesc="CLC_SEXP_F"/>
                into (/Respons/Request)[1]'
            )
         ELSE
            SET @Respons.modify(
               'insert <NextForm mtodnumb="36" mtoddesc="CLC_SAVE_F"/>
                into (/Respons/Request)[1]'
            )
	   END -- @MsttCode = 1 AND @SsttCode = 1	   
	   ELSE IF @MsttCode = 2 AND @SsttCode = 1
	   BEGIN
	      SET @Respons.modify(
	            'insert <NextForm mtodnumb="-1" mtoddesc=""/>
	             into (/Respons/Request)[1]'
	         )
	      GOTO End_Func;
	   END -- @MsttCode = 2 AND @SsttCode = 1
	   ELSE IF @MsttCode = 2 AND @SsttCode = 2
	   BEGIN
	      -- فرم تاييد پرداخت
	      IF @CrntForm = 35
	      BEGIN
	         SET @Respons.modify(
	            'insert <NextForm mtodnumb="-1" mtoddesc=""/>
	             into (/Respons/Request)[1]'
	         )
	         GOTO End_Func;
	      END
	      SET @Respons.modify(
            'insert <NextForm mtodnumb="35" mtoddesc="CLC_REXP_F"/>
             into (/Respons/Request)[1]'
         )
	   END
	   ELSE IF @MsttCode = 3 AND @SsttCode = 1
	   BEGIN
	      -- فرم تاييد پرداخت
	      SET @Respons.modify(
            'insert <NextForm mtodnumb="36" mtoddesc="CLC_SAVE_F"/>
             into (/Respons/Request)[1]'
         )
	   END
	END -- @RqtpCode = '003'
   /********************************
	*********************************
	*********************************/	
	ELSE IF @RqtpCode = '004'
	BEGIN
	   -- ثبت موقت
	   IF @MsttCode = 1 AND @SsttCode = 1
	   BEGIN	      
         -- اگر برای درخواست اعلام هزینه باید انجام بشود
         IF EXISTS(
            SELECT *
              FROM Request
             WHERE RQID = @Rqid
               AND SEND_EXPN = '002'
         )
            SET @Respons.modify(
               'insert <NextForm mtodnumb="38" mtoddesc="HRZ_SEXP_F"/>
                into (/Respons/Request)[1]'
            )
         ELSE
            SET @Respons.modify(
               'insert <NextForm mtodnumb="40" mtoddesc="HRZ_SAVE_F"/>
                into (/Respons/Request)[1]'
            )
	   END -- @MsttCode = 1 AND @SsttCode = 1	   
	   ELSE IF @MsttCode = 2 AND @SsttCode = 1
	   BEGIN
	      SET @Respons.modify(
	            'insert <NextForm mtodnumb="-1" mtoddesc=""/>
	             into (/Respons/Request)[1]'
	         )
	      GOTO End_Func;
	   END -- @MsttCode = 2 AND @SsttCode = 1
	   ELSE IF @MsttCode = 2 AND @SsttCode = 2
	   BEGIN
	      -- فرم تاييد پرداخت
	      IF @CrntForm = 39
	      BEGIN
	         SET @Respons.modify(
	            'insert <NextForm mtodnumb="-1" mtoddesc=""/>
	             into (/Respons/Request)[1]'
	         )
	         GOTO End_Func;
	      END
	      SET @Respons.modify(
            'insert <NextForm mtodnumb="39" mtoddesc="HRZ_REXP_F"/>
             into (/Respons/Request)[1]'
         )
	   END
	   ELSE IF @MsttCode = 3 AND @SsttCode = 1
	   BEGIN
	      -- فرم تاييد پرداخت
	      SET @Respons.modify(
            'insert <NextForm mtodnumb="40" mtoddesc="HRZ_SAVE_F"/>
             into (/Respons/Request)[1]'
         )
	   END
	END -- @RqtpCode = '003'
	/********************************
	*********************************
	*********************************/	
	ELSE IF @RqtpCode = '005'
	BEGIN
	   -- ثبت موقت
	   IF @MsttCode = 1 AND @SsttCode = 1
	   BEGIN	      
         -- اگر برای درخواست اعلام هزینه باید انجام بشود
         IF EXISTS(
            SELECT *
              FROM Request
             WHERE RQID = @Rqid
               AND SEND_EXPN = '002'
         )
            SET @Respons.modify(
               'insert <NextForm mtodnumb="30" mtoddesc="PSF_SEXP_F"/>
                into (/Respons/Request)[1]'
            )
         ELSE
            SET @Respons.modify(
               'insert <NextForm mtodnumb="32" mtoddesc="PSF_SAVE_F"/>
                into (/Respons/Request)[1]'
            )
	   END -- @MsttCode = 1 AND @SsttCode = 1	   
	   ELSE IF @MsttCode = 2 AND @SsttCode = 1
	   BEGIN
	      SET @Respons.modify(
	            'insert <NextForm mtodnumb="-1" mtoddesc=""/>
	             into (/Respons/Request)[1]'
	         )
	      GOTO End_Func;
	   END -- @MsttCode = 2 AND @SsttCode = 1
	   ELSE IF @MsttCode = 2 AND @SsttCode = 2
	   BEGIN
	      -- فرم تاييد پرداخت
	      IF @CrntForm = 31
	      BEGIN
	         SET @Respons.modify(
	            'insert <NextForm mtodnumb="-1" mtoddesc=""/>
	             into (/Respons/Request)[1]'
	         )
	         GOTO End_Func;
	      END
	      SET @Respons.modify(
            'insert <NextForm mtodnumb="31" mtoddesc="PSF_REXP_F"/>
             into (/Respons/Request)[1]'
         )
	   END
	   ELSE IF @MsttCode = 3 AND @SsttCode = 1
	   BEGIN
	      -- فرم تاييد پرداخت
	      SET @Respons.modify(
            'insert <NextForm mtodnumb="32" mtoddesc="PSF_SAVE_F"/>
             into (/Respons/Request)[1]'
         )
	   END
	END -- @RqtpCode = '005'
	/********************************
	*********************************
	*********************************/	
	ELSE IF @RqtpCode = '006'
	BEGIN
	   -- ثبت موقت
	   IF @MsttCode = 1 AND @SsttCode = 1
	   BEGIN
	      IF NOT EXISTS(
	         SELECT *
	           FROM Request_Row Rr, Test T
	          WHERE Rr.RQST_RQID    = T.RQRO_RQST_RQID
	            AND Rr.FIGH_FILE_NO = T.FIGH_FILE_NO
	            AND Rr.RQST_RQID    = @Rqid
	            AND Rr.RECD_STAT    = '002'
	            AND T.RECT_CODE     = '001'
	            AND (
	               /*T.CRET_DATE IS NULL OR
	               T.CRTF_NUMB IS NULL OR*/
	              (T.CTGY_CODE IS NULL OR T.CTGY_CODE = (SELECT CTGY_CODE_DNRM FROM Fighter WHERE FILE_NO = T.FIGH_FILE_NO)) OR
	              (T.CTGY_MTOD_CODE IS NULL OR T.CTGY_MTOD_CODE <> (SELECT MTOD_CODE_DNRM FROM Fighter WHERE FILE_NO = T.FIGH_FILE_NO)) OR
	               T.TEST_DATE IS NULL
	            )
	      )
	      BEGIN
	         -- اگر برای درخواست اعلام هزینه باید انجام بشود
	         IF EXISTS(
	            SELECT *
	              FROM Request
	             WHERE RQID = @Rqid
	               AND SEND_EXPN = '002'
	         )
	            SET @Respons.modify(
	               'insert <NextForm mtodnumb="22" mtoddesc="TST_SEXP_F"/>
	                into (/Respons/Request)[1]'
	            )
	         ELSE
	            SET @Respons.modify(
	               'insert <NextForm mtodnumb="24" mtoddesc="TST_SAVE_F"/>
	                into (/Respons/Request)[1]'
	            )
	      END
	      ELSE
	      BEGIN
	         SET @Respons.modify(
	            'insert <NextForm mtodnumb="-1" mtoddesc=""/>
	             into (/Respons/Request)[1]'
	         )
	         GOTO End_Func;
	      END
	   END -- @MsttCode = 1 AND @SsttCode = 1	   
	   ELSE IF @MsttCode = 2 AND @SsttCode = 1
	   BEGIN
	      SET @Respons.modify(
	            'insert <NextForm mtodnumb="-1" mtoddesc=""/>
	             into (/Respons/Request)[1]'
	         )
	      GOTO End_Func;
	   END -- @MsttCode = 2 AND @SsttCode = 1
	   ELSE IF @MsttCode = 2 AND @SsttCode = 2
	   BEGIN
	      -- فرم تاييد پرداخت
	      IF @CrntForm = 23
	      BEGIN
	         SET @Respons.modify(
	            'insert <NextForm mtodnumb="-1" mtoddesc=""/>
	             into (/Respons/Request)[1]'
	         )
	         GOTO End_Func;
	      END
	      SET @Respons.modify(
            'insert <NextForm mtodnumb="23" mtoddesc="TST_REXP_F"/>
             into (/Respons/Request)[1]'
         )
	   END
	   ELSE IF @MsttCode = 3 AND @SsttCode = 1
	   BEGIN
	      -- فرم تاييد پرداخت
	      SET @Respons.modify(
            'insert <NextForm mtodnumb="24" mtoddesc=""/>
             into (/Respons/Request)[1]'
         )
	   END
	END -- @RqtpCode = '006'
	/********************************
	*********************************
	*********************************/	
	ELSE IF @RqtpCode = '007'
	BEGIN
	   -- ثبت موقت
	   IF @MsttCode = 1 AND @SsttCode = 1
	   BEGIN	      
         -- اگر برای درخواست اعلام هزینه باید انجام بشود
         IF EXISTS(
            SELECT *
              FROM Request
             WHERE RQID = @Rqid
               AND SEND_EXPN = '002'
         )
            SET @Respons.modify(
               'insert <NextForm mtodnumb="42" mtoddesc="EXM_SEXP_F"/>
                into (/Respons/Request)[1]'
            )
         ELSE
            SET @Respons.modify(
               'insert <NextForm mtodnumb="44" mtoddesc="EXM_SAVE_F"/>
                into (/Respons/Request)[1]'
            )
	   END -- @MsttCode = 1 AND @SsttCode = 1	   
	   ELSE IF @MsttCode = 2 AND @SsttCode = 1
	   BEGIN
	      SET @Respons.modify(
	            'insert <NextForm mtodnumb="-1" mtoddesc=""/>
	             into (/Respons/Request)[1]'
	         )
	      GOTO End_Func;
	   END -- @MsttCode = 2 AND @SsttCode = 1
	   ELSE IF @MsttCode = 2 AND @SsttCode = 2
	   BEGIN
	      -- فرم تاييد پرداخت
	      IF @CrntForm = 43
	      BEGIN
	         SET @Respons.modify(
	            'insert <NextForm mtodnumb="-1" mtoddesc=""/>
	             into (/Respons/Request)[1]'
	         )
	         GOTO End_Func;
	      END
	      SET @Respons.modify(
            'insert <NextForm mtodnumb="43" mtoddesc="EXM_REXP_F"/>
             into (/Respons/Request)[1]'
         )
	   END
	   ELSE IF @MsttCode = 3 AND @SsttCode = 1
	   BEGIN
	      -- فرم تاييد پرداخت
	      SET @Respons.modify(
            'insert <NextForm mtodnumb="44" mtoddesc="EXM_SAVE_F"/>
             into (/Respons/Request)[1]'
         )
	   END
	END -- @RqtpCode = '007'
	/********************************
	*********************************
	*********************************/	
	ELSE IF @RqtpCode = '008'
	BEGIN
	   -- ثبت موقت
	   IF @MsttCode = 1 AND @SsttCode = 1
	   BEGIN
	      IF NOT EXISTS(
	         SELECT *
	           FROM Request_Row Rr, Campitition T
	          WHERE Rr.RQST_RQID    = T.RQRO_RQST_RQID
	            AND Rr.FIGH_FILE_NO = T.FIGH_FILE_NO
	            AND Rr.RQST_RQID    = @Rqid
	            AND Rr.RECD_STAT    = '002'
	            AND T.RECT_CODE     = '001'
	            AND (	               
	               T.CAMP_DATE IS NULL OR
	               T.PLAC_ADRS IS NULL OR LEN(T.PLAC_ADRS) = 0 OR 
	               T.SECT_NUMB IS NULL
	            )
	      )
	      BEGIN
	         -- اگر برای درخواست اعلام هزینه باید انجام بشود
	         IF EXISTS(
	            SELECT *
	              FROM Request
	             WHERE RQID = @Rqid
	               AND SEND_EXPN = '002'
	         )
	            SET @Respons.modify(
	               'insert <NextForm mtodnumb="26" mtoddesc="CMP_SEXP_F"/>
	                into (/Respons/Request)[1]'
	            )
	         ELSE
	            SET @Respons.modify(
	               'insert <NextForm mtodnumb="28" mtoddesc="CMP_SAVE_F"/>
	                into (/Respons/Request)[1]'
	            )
	      END
	      ELSE
	      BEGIN
	         SET @Respons.modify(
	            'insert <NextForm mtodnumb="-1" mtoddesc=""/>
	             into (/Respons/Request)[1]'
	         )
	         GOTO End_Func;
	      END
	   END -- @MsttCode = 1 AND @SsttCode = 1	   
	   ELSE IF @MsttCode = 2 AND @SsttCode = 1
	   BEGIN
	      SET @Respons.modify(
	            'insert <NextForm mtodnumb="-1" mtoddesc=""/>
	             into (/Respons/Request)[1]'
	         )
	      GOTO End_Func;
	   END -- @MsttCode = 2 AND @SsttCode = 1
	   ELSE IF @MsttCode = 2 AND @SsttCode = 2
	   BEGIN
	      -- فرم تاييد پرداخت
	      IF @CrntForm = 27
	      BEGIN
	         SET @Respons.modify(
	            'insert <NextForm mtodnumb="-1" mtoddesc=""/>
	             into (/Respons/Request)[1]'
	         )
	         GOTO End_Func;
	      END
	      SET @Respons.modify(
            'insert <NextForm mtodnumb="27" mtoddesc="CMP_REXP_F"/>
             into (/Respons/Request)[1]'
         )
	   END
	   ELSE IF @MsttCode = 3 AND @SsttCode = 1
	   BEGIN
	      -- فرم تاييد پرداخت
	      SET @Respons.modify(
            'insert <NextForm mtodnumb="28" mtoddesc="CMP_SAVE_F"/>
             into (/Respons/Request)[1]'
         )
	   END
	END -- @RqtpCode = '008'	
   /********************************
	*********************************
	*********************************/	
	ELSE IF @RqtpCode = '009'
	BEGIN
	   -- ثبت موقت
	   IF @MsttCode = 1 AND @SsttCode = 1
	   BEGIN
	      BEGIN
	         -- اگر برای درخواست اعلام هزینه باید انجام بشود
	         IF EXISTS(
	            SELECT *
	              FROM Request
	             WHERE RQID = @Rqid
	               AND SEND_EXPN = '002'
	         )
	            SET @Respons.modify(
	               'insert <NextForm mtodnumb="56" mtoddesc="UCC_SEXP_F"/>
	                into (/Respons/Request)[1]'
	            )
	         ELSE
	            SET @Respons.modify(
	               'insert <NextForm mtodnumb="58" mtoddesc="UCC_SAVE_F"/>
	                into (/Respons/Request)[1]'
	            )
	      END
	   END -- @MsttCode = 1 AND @SsttCode = 1	   
	   ELSE IF @MsttCode = 2 AND @SsttCode = 1
	   BEGIN
	      SET @Respons.modify(
	            'insert <NextForm mtodnumb="-1" mtoddesc=""/>
	             into (/Respons/Request)[1]'
	         )
	      GOTO End_Func;
	   END -- @MsttCode = 2 AND @SsttCode = 1
	   ELSE IF @MsttCode = 2 AND @SsttCode = 2
	   BEGIN
	      -- فرم تاييد پرداخت
	      IF @CrntForm = 57
	      BEGIN
	         SET @Respons.modify(
	            'insert <NextForm mtodnumb="-1" mtoddesc=""/>
	             into (/Respons/Request)[1]'
	         )
	         GOTO End_Func;
	      END
	      SET @Respons.modify(
            'insert <NextForm mtodnumb="57" mtoddesc="UCC_REXP_F"/>
             into (/Respons/Request)[1]'
         )
	   END
	   ELSE IF @MsttCode = 3 AND @SsttCode = 1
	   BEGIN
	      -- فرم تاييد پرداخت
	      SET @Respons.modify(
            'insert <NextForm mtodnumb="58" mtoddesc="UCC_SAVE_F"/>
             into (/Respons/Request)[1]'
         )
	   END
	END -- @RqtpCode = '009'
	/********************************
	*********************************
	*********************************/	
	ELSE IF @RqtpCode = '010'
	BEGIN
	   -- ثبت موقت
	   IF @MsttCode = 1 AND @SsttCode = 1
	   BEGIN
	      BEGIN
	         -- اگر برای درخواست اعلام هزینه باید انجام بشود
	         IF EXISTS(
	            SELECT *
	              FROM Request
	             WHERE RQID = @Rqid
	               AND SEND_EXPN = '002'
	         )
	            SET @Respons.modify(
	               'insert <NextForm mtodnumb="61" mtoddesc="MCC_SEXP_F"/>
	                into (/Respons/Request)[1]'
	            )
	         ELSE
	            SET @Respons.modify(
	               'insert <NextForm mtodnumb="63" mtoddesc="MCC_SAVE_F"/>
	                into (/Respons/Request)[1]'
	            )
	      END
	   END -- @MsttCode = 1 AND @SsttCode = 1	   
	   ELSE IF @MsttCode = 2 AND @SsttCode = 1
	   BEGIN
	      SET @Respons.modify(
	            'insert <NextForm mtodnumb="-1" mtoddesc=""/>
	             into (/Respons/Request)[1]'
	         )
	      GOTO End_Func;
	   END -- @MsttCode = 2 AND @SsttCode = 1
	   ELSE IF @MsttCode = 2 AND @SsttCode = 2
	   BEGIN
	      -- فرم تاييد پرداخت
	      IF @CrntForm = 62
	      BEGIN
	         SET @Respons.modify(
	            'insert <NextForm mtodnumb="-1" mtoddesc=""/>
	             into (/Respons/Request)[1]'
	         )
	         GOTO End_Func;
	      END
	      SET @Respons.modify(
            'insert <NextForm mtodnumb="62" mtoddesc="MCC_REXP_F"/>
             into (/Respons/Request)[1]'
         )
	   END
	   ELSE IF @MsttCode = 3 AND @SsttCode = 1
	   BEGIN
	      -- فرم تاييد پرداخت
	      SET @Respons.modify(
            'insert <NextForm mtodnumb="63" mtoddesc="MCC_SAVE_F"/>
             into (/Respons/Request)[1]'
         )
	   END
	END -- @RqtpCode = '010'
	/********************************
	*********************************
	*********************************/	
	ELSE IF @RqtpCode = '011'
	BEGIN
	   -- ثبت موقت
	   IF @MsttCode = 1 AND @SsttCode = 1
	   BEGIN	      
         -- اگر برای درخواست اعلام هزینه باید انجام بشود
         IF EXISTS(
            SELECT *
              FROM Request
             WHERE RQID = @Rqid
               AND SEND_EXPN = '002'
         )
            SET @Respons.modify(
               'insert <NextForm mtodnumb="52" mtoddesc="CMC_SEXP_F"/>
                into (/Respons/Request)[1]'
            )
         ELSE
            SET @Respons.modify(
               'insert <NextForm mtodnumb="54" mtoddesc="CMC_SAVE_F"/>
                into (/Respons/Request)[1]'
            )
	   END -- @MsttCode = 1 AND @SsttCode = 1	   
	   ELSE IF @MsttCode = 2 AND @SsttCode = 1
	   BEGIN
	      SET @Respons.modify(
	            'insert <NextForm mtodnumb="-1" mtoddesc=""/>
	             into (/Respons/Request)[1]'
	         )
	      GOTO End_Func;
	   END -- @MsttCode = 2 AND @SsttCode = 1
	   ELSE IF @MsttCode = 2 AND @SsttCode = 2
	   BEGIN
	      -- فرم تاييد پرداخت
	      IF @CrntForm = 53
	      BEGIN
	         SET @Respons.modify(
	            'insert <NextForm mtodnumb="-1" mtoddesc=""/>
	             into (/Respons/Request)[1]'
	         )
	         GOTO End_Func;
	      END
	      SET @Respons.modify(
            'insert <NextForm mtodnumb="53" mtoddesc="CMC_REXP_F"/>
             into (/Respons/Request)[1]'
         )
	   END
	   ELSE IF @MsttCode = 3 AND @SsttCode = 1
	   BEGIN
	      -- فرم تاييد پرداخت
	      SET @Respons.modify(
            'insert <NextForm mtodnumb="54" mtoddesc="CMC_SAVE_F"/>
             into (/Respons/Request)[1]'
         )
	   END
	END -- @RqtpCode = '011'
	End_Func:
	RETURN @Respons;
END
GO
