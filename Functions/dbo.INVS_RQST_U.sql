SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[INVS_RQST_U]
(
	@X XML
)
RETURNS XML
AS
BEGIN
	DECLARE @Rqid BIGINT
	       ,@RqtpCode VARCHAR(3)
	       ,@RqstStat VARCHAR(3)
	       ,@SsttCode SMALLINT
	       ,@MsttCode SMALLINT
	       ,@SendExpn VARCHAR(3);
	
	SELECT @Rqid = @X.query('//Request').value('(Request/@rqid)[1]', 'BIGINT');
	SELECT @RqtpCode = RQTP_CODE
	      ,@RqstStat = RQST_STAT
	      ,@SsttCode = SSTT_CODE
	      ,@MsttCode = SSTT_MSTT_CODE
	      ,@SendExpn = SEND_EXPN
	  FROM Request
	 WHERE RQID = @Rqid;
	
	DECLARE @Respons XML;
	SET @Respons = '<Respons><Request rqid=""/></Respons>';
	SET @Respons.modify(
	   'replace value of (//Request/@rqid)[1]
	    with sql:variable("@Rqid")'
	);
	
	IF NOT EXISTS(
	   SELECT *
	     FROM Request_Row
	    WHERE RQST_RQID = @Rqid
	      AND RECD_STAT = '002'
	)
	BEGIN
	   SET @Respons.modify(
         N'insert <NextForm mtodnumb="-1" mtoddesc="درون درخواست ردیف معتبری وجود ندارد"/>
          into (/Respons/Request)[1]'
      )
      GOTO End_Invs;
	END
	
	IF @RqstStat = '002'
	BEGIN
	   SET @Respons.modify(
         N'insert <NextForm mtodnumb="-1" mtoddesc="درخواست در وضعیت پایانی قرار گرفته شده است"/>
          into (/Respons/Request)[1]'
      )
      GOTO End_Invs;
	END	
	ELSE IF @RqstStat = '003'
	BEGIN
	   SET @Respons.modify(
         N'insert <NextForm mtodnumb="-1" mtoddesc="درخواست در وضعیت انصراف قرار گرفته شده است"/>
          into (/Respons/Request)[1]'
      )	
      GOTO End_Invs;
	END
	
	IF @RqtpCode = '001'
	BEGIN
	   IF @MsttCode = 1 AND @SsttCode = 1 
	   AND EXISTS(
	         SELECT *
	           FROM Fighter F, Fighter_Public P, Category_Belt C
	          WHERE F.FILE_NO = P.FIGH_FILE_NO
	            AND P.CTGY_CODE = C.CODE
	            AND C.ORDR <> 0
	            AND F.RQST_RQID = @Rqid
	            AND P.RECT_CODE = '001'	           
	      )
      BEGIN
         SET @Respons.modify(
            'insert <NextForm mtodnumb="16" mtoddesc="ADM_FSUM_F"/>
             into (/Respons/Request)[1]'
         );
         GOTO End_Invs;
      END
      ELSE IF @MsttCode IN (1, 4) AND @SsttCode = 1 
      AND EXISTS(
         SELECT *
           FROM Request R, Request_Row Rr, Fighter F
          WHERE R.RQID = RR.RQST_RQID
            AND Rr.FIGH_FILE_NO = F.FILE_NO
            AND Rr.RQST_RQID = @Rqid
            AND EXISTS(
               SELECT *
                 FROM dbo.VF$All_Expense_Detail(R.REGN_PRVN_CODE, R.REGN_CODE, NULL, @RqtpCode, R.RQTT_CODE, NULL, NULL, F.Mtod_Code_Dnrm , F.Ctgy_Code_Dnrm)
            )
      )
      BEGIN
         SET @Respons.modify(
            'insert <NextForm mtodnumb="17" mtoddesc="ADM_SEXP_F"/>
             into (/Respons/Request)[1]'
         );
         GOTO End_Invs;
      END
      ELSE IF @MsttCode IN (1, 3, 4) AND @SsttCode = 1 
      BEGIN
         SET @Respons.modify(
            'insert <NextForm mtodnumb="19" mtoddesc="ADM_SAVE_F"/>
             into (/Respons/Request)[1]'
         );
         GOTO End_Invs;
      END
      ELSE IF @MsttCode IN (2) AND @SsttCode = 1 
      BEGIN
         SET @Respons.modify(
            'insert <NextForm mtodnumb="17" mtoddesc="ADM_SEXP_F"/>
             into (/Respons/Request)[1]'
         );
         GOTO End_Invs;
      END	   	   
      ELSE IF @MsttCode IN (2) AND @SsttCode = 2
      BEGIN
         SET @Respons.modify(
            'insert <NextForm mtodnumb="18" mtoddesc="ADM_REXP_F"/>
             into (/Respons/Request)[1]'
         );
         GOTO End_Invs;
      END	   	   
	END
	ELSE IF @RqtpCode = '002'
	BEGIN
      IF @MsttCode IN (1) AND @SsttCode = 1 
      AND EXISTS(
         SELECT *
           FROM Request R, Request_Row Rr, Fighter F
          WHERE R.RQID = RR.RQST_RQID
            AND Rr.FIGH_FILE_NO = F.FILE_NO
            AND Rr.RQST_RQID = @Rqid
            AND EXISTS(
               SELECT *
                 FROM dbo.VF$All_Expense_Detail(R.REGN_PRVN_CODE, R.REGN_CODE, NULL, @RqtpCode, R.RQTT_CODE, NULL, NULL, F.Mtod_Code_Dnrm , F.Ctgy_Code_Dnrm)
            )
      )
      BEGIN
         SET @Respons.modify(
            'insert <NextForm mtodnumb="48" mtoddesc="PBL_SEXP_F"/>
             into (/Respons/Request)[1]'
         );
         GOTO End_Invs;
      END
      ELSE IF @MsttCode IN (1, 3) AND @SsttCode = 1 
      BEGIN
         SET @Respons.modify(
            'insert <NextForm mtodnumb="50" mtoddesc="PBL_SAVE_F"/>
             into (/Respons/Request)[1]'
         );
         GOTO End_Invs;
      END
      ELSE IF @MsttCode IN (2) AND @SsttCode = 1 
      BEGIN
         SET @Respons.modify(
            'insert <NextForm mtodnumb="48" mtoddesc="PBL_SEXP_F"/>
             into (/Respons/Request)[1]'
         );
         GOTO End_Invs;
      END	   	   
      ELSE IF @MsttCode IN (2) AND @SsttCode = 2
      BEGIN
         SET @Respons.modify(
            'insert <NextForm mtodnumb="49" mtoddesc="PBL_REXP_F"/>
             into (/Respons/Request)[1]'
         );
         GOTO End_Invs;
      END	   	   
	END
	ELSE IF @RqtpCode = '003'
	BEGIN
      IF @MsttCode IN (1) AND @SsttCode = 1 
      AND EXISTS(
         SELECT *
           FROM Request R, Request_Row Rr, Fighter F
          WHERE R.RQID = RR.RQST_RQID
            AND Rr.FIGH_FILE_NO = F.FILE_NO
            AND Rr.RQST_RQID = @Rqid
            AND EXISTS(
               SELECT *
                 FROM dbo.VF$All_Expense_Detail(R.REGN_PRVN_CODE, R.REGN_CODE, NULL, @RqtpCode, R.RQTT_CODE, NULL, NULL, F.Mtod_Code_Dnrm , F.Ctgy_Code_Dnrm)
            )
      )
      BEGIN
         SET @Respons.modify(
            'insert <NextForm mtodnumb="34" mtoddesc="CLC_SEXP_F"/>
             into (/Respons/Request)[1]'
         );
         GOTO End_Invs;
      END
      ELSE IF @MsttCode IN (1, 3) AND @SsttCode = 1 
      BEGIN
         SET @Respons.modify(
            'insert <NextForm mtodnumb="36" mtoddesc="CLC_SAVE_F"/>
             into (/Respons/Request)[1]'
         );
         GOTO End_Invs;
      END
      ELSE IF @MsttCode IN (2) AND @SsttCode = 1 
      BEGIN
         SET @Respons.modify(
            'insert <NextForm mtodnumb="34" mtoddesc="CLC_SEXP_F"/>
             into (/Respons/Request)[1]'
         );
         GOTO End_Invs;
      END	   	   
      ELSE IF @MsttCode IN (2) AND @SsttCode = 2
      BEGIN
         SET @Respons.modify(
            'insert <NextForm mtodnumb="35" mtoddesc="CLC_REXP_F"/>
             into (/Respons/Request)[1]'
         );
         GOTO End_Invs;
      END	   	   
	END
		ELSE IF @RqtpCode = '004'
	BEGIN
      IF @MsttCode IN (1) AND @SsttCode = 1 
      AND EXISTS(
         SELECT *
           FROM Request R, Request_Row Rr, Fighter F
          WHERE R.RQID = RR.RQST_RQID
            AND Rr.FIGH_FILE_NO = F.FILE_NO
            AND Rr.RQST_RQID = @Rqid
            AND EXISTS(
               SELECT *
                 FROM dbo.VF$All_Expense_Detail(R.REGN_PRVN_CODE, R.REGN_CODE, NULL, @RqtpCode, R.RQTT_CODE, NULL, NULL, F.Mtod_Code_Dnrm , F.Ctgy_Code_Dnrm)
            )
      )
      BEGIN
         SET @Respons.modify(
            'insert <NextForm mtodnumb="38" mtoddesc="HRT_SEXP_F"/>
             into (/Respons/Request)[1]'
         );
         GOTO End_Invs;
      END
      ELSE IF @MsttCode IN (1, 3) AND @SsttCode = 1 
      BEGIN
         SET @Respons.modify(
            'insert <NextForm mtodnumb="40" mtoddesc="HRT_SAVE_F"/>
             into (/Respons/Request)[1]'
         );
         GOTO End_Invs;
      END
      ELSE IF @MsttCode IN (2) AND @SsttCode = 1 
      BEGIN
         SET @Respons.modify(
            'insert <NextForm mtodnumb="38" mtoddesc="HRT_SEXP_F"/>
             into (/Respons/Request)[1]'
         );
         GOTO End_Invs;
      END	   	   
      ELSE IF @MsttCode IN (2) AND @SsttCode = 2
      BEGIN
         SET @Respons.modify(
            'insert <NextForm mtodnumb="39" mtoddesc="HRT_REXP_F"/>
             into (/Respons/Request)[1]'
         );
         GOTO End_Invs;
      END	   	   
	END
   ELSE IF @RqtpCode = '005'
	BEGIN
      IF @MsttCode IN (1) AND @SsttCode = 1 
      AND EXISTS(
         SELECT *
           FROM Request R, Request_Row Rr, Fighter F
          WHERE R.RQID = RR.RQST_RQID
            AND Rr.FIGH_FILE_NO = F.FILE_NO
            AND Rr.RQST_RQID = @Rqid
            AND EXISTS(
               SELECT *
                 FROM dbo.VF$All_Expense_Detail(R.REGN_PRVN_CODE, R.REGN_CODE, NULL, @RqtpCode, R.RQTT_CODE, NULL, NULL, F.Mtod_Code_Dnrm , F.Ctgy_Code_Dnrm)
            )
      )
      BEGIN
         SET @Respons.modify(
            'insert <NextForm mtodnumb="30" mtoddesc="PSF_SEXP_F"/>
             into (/Respons/Request)[1]'
         );
         GOTO End_Invs;
      END
      ELSE IF @MsttCode IN (1, 3) AND @SsttCode = 1 
      BEGIN
         SET @Respons.modify(
            'insert <NextForm mtodnumb="32" mtoddesc="PSF_SAVE_F"/>
             into (/Respons/Request)[1]'
         );
         GOTO End_Invs;
      END
      ELSE IF @MsttCode IN (2) AND @SsttCode = 1 
      BEGIN
         SET @Respons.modify(
            'insert <NextForm mtodnumb="30" mtoddesc="PSF_SEXP_F"/>
             into (/Respons/Request)[1]'
         );
         GOTO End_Invs;
      END	   	   
      ELSE IF @MsttCode IN (2) AND @SsttCode = 2
      BEGIN
         SET @Respons.modify(
            'insert <NextForm mtodnumb="31" mtoddesc="PSF_REXP_F"/>
             into (/Respons/Request)[1]'
         );
         GOTO End_Invs;
      END	   	   
	END
	ELSE IF @RqtpCode = '006'
	BEGIN
	      IF @MsttCode IN (1) AND @SsttCode = 1 
      AND EXISTS(
         SELECT *
           FROM Request R, Request_Row Rr, Fighter F
          WHERE R.RQID = RR.RQST_RQID
            AND Rr.FIGH_FILE_NO = F.FILE_NO
            AND Rr.RQST_RQID = @Rqid
            AND EXISTS(
               SELECT *
                 FROM dbo.VF$All_Expense_Detail(R.REGN_PRVN_CODE, R.REGN_CODE, NULL, @RqtpCode, R.RQTT_CODE, NULL, NULL, F.Mtod_Code_Dnrm , F.Ctgy_Code_Dnrm)
            )
      )
      BEGIN
         SET @Respons.modify(
            'insert <NextForm mtodnumb="22" mtoddesc="TST_SEXP_F"/>
             into (/Respons/Request)[1]'
         );
         GOTO End_Invs;
      END
      ELSE IF @MsttCode IN (1, 3) AND @SsttCode = 1 
      BEGIN
         SET @Respons.modify(
            'insert <NextForm mtodnumb="24" mtoddesc="TST_SAVE_F"/>
             into (/Respons/Request)[1]'
         );
         GOTO End_Invs;
      END
      ELSE IF @MsttCode IN (2) AND @SsttCode = 1 
      BEGIN
         SET @Respons.modify(
            'insert <NextForm mtodnumb="22" mtoddesc="TST_SEXP_F"/>
             into (/Respons/Request)[1]'
         );
         GOTO End_Invs;
      END	   	   
      ELSE IF @MsttCode IN (2) AND @SsttCode = 2
      BEGIN
         SET @Respons.modify(
            'insert <NextForm mtodnumb="23" mtoddesc="PBL_REXP_F"/>
             into (/Respons/Request)[1]'
         );
         GOTO End_Invs;
      END	   	   
	END
	ELSE IF @RqtpCode = '007'
	BEGIN
      IF @MsttCode IN (1) AND @SsttCode = 1 
      AND EXISTS(
         SELECT *
           FROM Request R, Request_Row Rr, Fighter F
          WHERE R.RQID = RR.RQST_RQID
            AND Rr.FIGH_FILE_NO = F.FILE_NO
            AND Rr.RQST_RQID = @Rqid
            AND EXISTS(
               SELECT *
                 FROM dbo.VF$All_Expense_Detail(R.REGN_PRVN_CODE, R.REGN_CODE, NULL, @RqtpCode, R.RQTT_CODE, NULL, NULL, F.Mtod_Code_Dnrm , F.Ctgy_Code_Dnrm)
            )
      )
      BEGIN
         SET @Respons.modify(
            'insert <NextForm mtodnumb="42" mtoddesc="EXM_SEXP_F"/>
             into (/Respons/Request)[1]'
         );
         GOTO End_Invs;
      END
      ELSE IF @MsttCode IN (1, 3) AND @SsttCode = 1 
      BEGIN
         SET @Respons.modify(
            'insert <NextForm mtodnumb="44" mtoddesc="EXM_SAVE_F"/>
             into (/Respons/Request)[1]'
         );
         GOTO End_Invs;
      END
      ELSE IF @MsttCode IN (2) AND @SsttCode = 1 
      BEGIN
         SET @Respons.modify(
            'insert <NextForm mtodnumb="42" mtoddesc="EXM_SEXP_F"/>
             into (/Respons/Request)[1]'
         );
         GOTO End_Invs;
      END	   	   
      ELSE IF @MsttCode IN (2) AND @SsttCode = 2
      BEGIN
         SET @Respons.modify(
            'insert <NextForm mtodnumb="43" mtoddesc="EXM_REXP_F"/>
             into (/Respons/Request)[1]'
         );
         GOTO End_Invs;
      END	   	   
	END
	ELSE IF @RqtpCode = '008'
	BEGIN
      IF @MsttCode IN (1) AND @SsttCode = 1 
      AND EXISTS(
         SELECT *
           FROM Request R, Request_Row Rr, Fighter F
          WHERE R.RQID = RR.RQST_RQID
            AND Rr.FIGH_FILE_NO = F.FILE_NO
            AND Rr.RQST_RQID = @Rqid
            AND EXISTS(
               SELECT *
                 FROM dbo.VF$All_Expense_Detail(R.REGN_PRVN_CODE, R.REGN_CODE, NULL, @RqtpCode, R.RQTT_CODE, NULL, NULL, F.Mtod_Code_Dnrm , F.Ctgy_Code_Dnrm)
            )
      )
      BEGIN
         SET @Respons.modify(
            'insert <NextForm mtodnumb="26" mtoddesc="CMP_SEXP_F"/>
             into (/Respons/Request)[1]'
         );
         GOTO End_Invs;
      END
      ELSE IF @MsttCode IN (1, 3) AND @SsttCode = 1 
      BEGIN
         SET @Respons.modify(
            'insert <NextForm mtodnumb="28" mtoddesc="CMP_SAVE_F"/>
             into (/Respons/Request)[1]'
         );
         GOTO End_Invs;
      END
      ELSE IF @MsttCode IN (2) AND @SsttCode = 1 
      BEGIN
         SET @Respons.modify(
            'insert <NextForm mtodnumb="26" mtoddesc="CMP_SEXP_F"/>
             into (/Respons/Request)[1]'
         );
         GOTO End_Invs;
      END	   	   
      ELSE IF @MsttCode IN (2) AND @SsttCode = 2
      BEGIN
         SET @Respons.modify(
            'insert <NextForm mtodnumb="27" mtoddesc="CMP_REXP_F"/>
             into (/Respons/Request)[1]'
         );
         GOTO End_Invs;
      END	   	   
	END
	ELSE IF @RqtpCode = '009'
	BEGIN
      IF @MsttCode IN (1) AND @SsttCode = 1 
      AND EXISTS(
         SELECT *
           FROM Request R, Request_Row Rr, Fighter F
          WHERE R.RQID = RR.RQST_RQID
            AND Rr.FIGH_FILE_NO = F.FILE_NO
            AND Rr.RQST_RQID = @Rqid
            AND EXISTS(
               SELECT *
                 FROM dbo.VF$All_Expense_Detail(R.REGN_PRVN_CODE, R.REGN_CODE, NULL, @RqtpCode, R.RQTT_CODE, NULL, NULL, F.Mtod_Code_Dnrm , F.Ctgy_Code_Dnrm)
            )
      )
      BEGIN
         SET @Respons.modify(
            'insert <NextForm mtodnumb="56" mtoddesc="UCC_SEXP_F"/>
             into (/Respons/Request)[1]'
         );
         GOTO End_Invs;
      END
      ELSE IF @MsttCode IN (1, 3) AND @SsttCode = 1 
      BEGIN
         SET @Respons.modify(
            'insert <NextForm mtodnumb="58" mtoddesc="UCC_SAVE_F"/>
             into (/Respons/Request)[1]'
         );
         GOTO End_Invs;
      END
      ELSE IF @MsttCode IN (2) AND @SsttCode = 1 
      BEGIN
         SET @Respons.modify(
            'insert <NextForm mtodnumb="56" mtoddesc="UCC_SEXP_F"/>
             into (/Respons/Request)[1]'
         );
         GOTO End_Invs;
      END	   	   
      ELSE IF @MsttCode IN (2) AND @SsttCode = 2
      BEGIN
         SET @Respons.modify(
            'insert <NextForm mtodnumb="57" mtoddesc="UCC_REXP_F"/>
             into (/Respons/Request)[1]'
         );
         GOTO End_Invs;
      END	   	   
	END	
		ELSE IF @RqtpCode = '010'
	BEGIN
      IF @MsttCode IN (1) AND @SsttCode = 1 
      AND EXISTS(
         SELECT *
           FROM Request R, Request_Row Rr, Fighter F
          WHERE R.RQID = RR.RQST_RQID
            AND Rr.FIGH_FILE_NO = F.FILE_NO
            AND Rr.RQST_RQID = @Rqid
            AND EXISTS(
               SELECT *
                 FROM dbo.VF$All_Expense_Detail(R.REGN_PRVN_CODE, R.REGN_CODE, NULL, @RqtpCode, R.RQTT_CODE, NULL, NULL, F.Mtod_Code_Dnrm , F.Ctgy_Code_Dnrm)
            )
      )
      BEGIN
         SET @Respons.modify(
            'insert <NextForm mtodnumb="61" mtoddesc="MCC_SEXP_F"/>
             into (/Respons/Request)[1]'
         );
         GOTO End_Invs;
      END
      ELSE IF @MsttCode IN (1, 3) AND @SsttCode = 1 
      BEGIN
         SET @Respons.modify(
            'insert <NextForm mtodnumb="63" mtoddesc="MCC_SAVE_F"/>
             into (/Respons/Request)[1]'
         );
         GOTO End_Invs;
      END
      ELSE IF @MsttCode IN (2) AND @SsttCode = 1 
      BEGIN
         SET @Respons.modify(
            'insert <NextForm mtodnumb="61" mtoddesc="MCC_SEXP_F"/>
             into (/Respons/Request)[1]'
         );
         GOTO End_Invs;
      END	   	   
      ELSE IF @MsttCode IN (2) AND @SsttCode = 2
      BEGIN
         SET @Respons.modify(
            'insert <NextForm mtodnumb="62" mtoddesc="MCC_REXP_F"/>
             into (/Respons/Request)[1]'
         );
         GOTO End_Invs;
      END	   	   
	END	
	ELSE IF @RqtpCode = '011'
	BEGIN
      IF @MsttCode IN (1) AND @SsttCode = 1 
      AND EXISTS(
         SELECT *
           FROM Request R, Request_Row Rr, Fighter F
          WHERE R.RQID = RR.RQST_RQID
            AND Rr.FIGH_FILE_NO = F.FILE_NO
            AND Rr.RQST_RQID = @Rqid
            AND EXISTS(
               SELECT *
                 FROM dbo.VF$All_Expense_Detail(R.REGN_PRVN_CODE, R.REGN_CODE, NULL, @RqtpCode, R.RQTT_CODE, NULL, NULL, F.Mtod_Code_Dnrm , F.Ctgy_Code_Dnrm)
            )
      )
      BEGIN
         SET @Respons.modify(
            'insert <NextForm mtodnumb="52" mtoddesc="CMC_SEXP_F"/>
             into (/Respons/Request)[1]'
         );
         GOTO End_Invs;
      END
      ELSE IF @MsttCode IN (1, 3) AND @SsttCode = 1 
      BEGIN
         SET @Respons.modify(
            'insert <NextForm mtodnumb="54" mtoddesc="CMC_SAVE_F"/>
             into (/Respons/Request)[1]'
         );
         GOTO End_Invs;
      END
      ELSE IF @MsttCode IN (2) AND @SsttCode = 1 
      BEGIN
         SET @Respons.modify(
            'insert <NextForm mtodnumb="52" mtoddesc="CMC_SEXP_F"/>
             into (/Respons/Request)[1]'
         );
         GOTO End_Invs;
      END	   	   
      ELSE IF @MsttCode IN (2) AND @SsttCode = 2
      BEGIN
         SET @Respons.modify(
            'insert <NextForm mtodnumb="53" mtoddesc="CMC_REXP_F"/>
             into (/Respons/Request)[1]'
         );
         GOTO End_Invs;
      END	   	   
	END
	End_Invs:
	RETURN @Respons;
END
GO
