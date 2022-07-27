SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[VF$Last_Info_Fighter]
(@FileNo bigint, @FrstName nvarchar(250), @LastName nvarchar(250), @NatlCode varchar(10), @FngrPrnt varchar(20), @CellPhon varchar(11), @TellPhon varchar(11), @SexType varchar(3), @ServNo nvarchar(50), @GlobCode nvarchar(50), @MomCellPhon varchar(11), @MomTellPhon varchar(11), @DadCellPHon varchar(11), @DadTellPHon varchar(11), @SuntCode varchar(4))
RETURNS table
AS
RETURN
(
SELECT     f.FILE_NO, 
           f.DEBT_DNRM, 
           f.DPST_AMNT_DNRM,
           f.BUFE_DEBT_DNTM, 
           f.REGN_PRVN_CODE, 
           f.REGN_CODE, 
           f.FGPB_RWNO_DNRM, 
           f.MBSP_RWNO_DNRM, 
           f.CAMP_RWNO_DNRM, 
           f.TEST_RWNO_DNRM, 
           f.CLCL_RWNO_DNRM, 
           f.HERT_RWNO_DNRM, 
           f.PSFN_RWNO_DNRM, 
           f.CONF_DATE, 
           f.RQST_RQID, 
           f.CHAT_ID_DNRM,
           f.NAME_DNRM, 
           f.FATH_NAME_DNRM, 
           f.BRTH_DATE_DNRM, 
           f.CELL_PHON_DNRM, 
           f.TELL_PHON_DNRM, 
           f.INSR_NUMB_DNRM, 
           f.INSR_DATE_DNRM, 
           f.TEST_DATE_DNRM, 
           f.CAMP_DATE_DNRM, 
           f.NATL_CODE_DNRM AS NATL_CODE, 
           f.GLOB_CODE_DNRM AS GLOB_CODE,
           --f.FMLY_NUMB_DNRM AS FMLY_NUMB, 
           f.POST_ADRS_DNRM AS POST_ADRS, 
           f.FRST_NAME_DNRM AS FRST_NAME, 
           f.LAST_NAME_DNRM AS LAST_NAME,
           f.FGPB_TYPE_DNRM AS TYPE, 
           f.CBMT_CODE_DNRM AS CBMT_CODE,           
           NULL AS EMAL_ADRS, 
           NULL AS DISE_DESC, 
           NULL AS CLUB_NAME, 
           f.CLUB_CODE_DNRM AS CLUB_CODE, 
           dbo.D$FGTP.DOMN_DESC AS TYPE_DESC, 
           NULL AS COCH_DEGR, 
           f.COCH_FILE_NO_DNRM AS COCH_FILE_NO, 
           f.ACTV_TAG_DNRM, 
           f.MOST_DEBT_CLNG_DNRM,
           NULL AS GUGD_DEGR, 
           dbo.D$SXTP.DOMN_DESC AS SEX_TYPE, 
           dbo.D$FGST.DOMN_DESC AS FIGH_STAT, 
           NULL AS MTOD_DESC, 
           NULL AS CTGY_DESC,
           dbo.D$ACTG.DOMN_DESC AS ACTV_TAG, 
           NULL AS REGN_NAME, 
           NULL AS PRVN_NAME, 
           NULL AS BLOD_GROP, 
           NULL AS RQTP_DESC, 
           f.FNGR_PRNT_DNRM,
           f.SUNT_BUNT_DEPT_ORGN_CODE_DNRM AS SUNT_BUNT_DEPT_ORGN_CODE, 
           f.SUNT_BUNT_DEPT_CODE_DNRM AS SUNT_BUNT_DEPT_CODE, 
           f.SUNT_BUNT_CODE_DNRM AS SUNT_BUNT_CODE, 
           f.SUNT_CODE_DNRM AS SUNT_CODE,
           NULL AS ORGN_DESC, 
           NULL AS DEPT_DESC, 
           NULL AS BUNT_DESC, 
           s.SUNT_DESC,
           f.MBSP_STRT_DATE AS STRT_DATE,
           f.MBSP_END_DATE AS END_DATE, 
           0 AS NUMB_OF_MONT_DNRM, 
           0 AS NUMB_OF_DAYS_DNRM, 
           0 AS NUMB_MONT_OFER,
           0 AS NUMB_OF_ATTN_MONT, 
           0 AS NUMB_OF_ATTN_WEEK, 
           0 AS SUM_ATTN_MONT_DNRM, 
           0 AS SUM_ATTN_WEEK_DNRM,
           f.MOM_CELL_PHON_DNRM,
           f.MOM_TELL_PHON_DNRM,
           f.MOM_CHAT_ID_DNRM,
           f.DAD_CELL_PHON_DNRM,
           f.DAD_TELL_PHON_DNRM,
           f.DAD_CHAT_ID_DNRM,
           f.SERV_NO_DNRM
FROM       dbo.Fighter f,           
           dbo.Sub_Unit s,
           dbo.[D$FGTP],
           dbo.[D$SXTP],
           dbo.[D$FGST],
           dbo.[D$ACTG],
           dbo.Club C, 
           dbo.V#UCFGA P, 
           dbo.V#URFGA R	       
WHERE (f.CONF_STAT = '002')
  AND f.SUNT_BUNT_DEPT_ORGN_CODE_DNRM = s.BUNT_DEPT_ORGN_CODE
  AND f.SUNT_BUNT_DEPT_CODE_DNRM = s.BUNT_DEPT_CODE
  AND f.SUNT_BUNT_CODE_DNRM = s.BUNT_CODE
  AND f.SUNT_CODE_DNRM = s.CODE
  AND f.FGPB_TYPE_DNRM = dbo.[D$FGTP].VALU
  AND f.SEX_TYPE_DNRM = dbo.[D$SXTP].VALU
  AND f.FIGH_STAT = dbo.[D$FGST].VALU
  AND f.ACTV_TAG_DNRM = dbo.[D$ACTG].VALU  
  AND (f.ACTV_TAG_DNRM >= '101')
  
  AND (f.FGPB_TYPE_DNRM IN ( '002',/*'003',*/ '004' ) OR /*dbo.PLC_CLUB_U('<Club code="' + CAST(f.CLUB_CODE_DNRM AS VARCHAR(20)) + '"/>') = '002'*/        
      (
            C.REGN_PRVN_CODE = R.REGN_PRVN_CODE
        AND C.REGN_CODE = R.REGN_CODE
        AND C.CODE = P.CLUB_CODE
        AND C.CODE = f.CLUB_CODE_DNRM
        AND P.SYS_USER = UPPER(SUSER_NAME())
        AND R.SYS_USER = UPPER(SUSER_NAME())
      )
  )
    
  AND (@FileNo IS NULL OR f.FILE_NO = @FileNo)
  AND (@FrstName IS NULL OR @FrstName = '' OR f.FRST_NAME_DNRM LIKE N'%' + @FrstName + N'%')
  AND (@LastName IS NULL OR @LastName = '' OR f.LAST_NAME_DNRM LIKE N'%' + @LastName + N'%')
  AND (@NatlCode IS NULL OR @NatlCode = '' OR f.NATL_CODE_DNRM LIKE N'%' + @NatlCode + N'%')
  AND (@FngrPrnt IS NULL OR @FngrPrnt = '' OR f.FNGR_PRNT_DNRM LIKE N'%' + @FngrPrnt + N'%')
  AND (@CellPhon IS NULL OR @CellPhon = '' OR f.CELL_PHON_DNRM LIKE N'%' + @CellPhon + N'%')
  AND (@TellPhon IS NULL OR @TellPhon = '' OR f.TELL_PHON_DNRM LIKE N'%' + @TellPhon + N'%')
  AND (@ServNo IS NULL OR @ServNo = '' OR f.SERV_NO_DNRM LIKE @ServNo)
  AND (@GlobCode IS NULL OR @GlobCode = '' OR f.GLOB_CODE_DNRM LIKE @GlobCode )
  AND (@SexType IS NULL OR @SexType = '' OR f.SEX_TYPE_DNRM LIKE @SexType)  
  AND (@MomCellPhon IS NULL OR @MomCellPhon = '' OR f.MOM_CELL_PHON_DNRM LIKE N'%' + @MomCellPhon + N'%')
  AND (@MomTellPhon IS NULL OR @MomTellPhon = '' OR f.MOM_TELL_PHON_DNRM LIKE N'%' + @MomTellPhon + N'%')
  AND (@DadCellPhon IS NULL OR @DadCellPhon = '' OR f.DAD_CELL_PHON_DNRM LIKE N'%' + @DadCellPhon + N'%')
  AND (@DadTellPhon IS NULL OR @DadTellPhon = '' OR f.DAD_TELL_PHON_DNRM LIKE N'%' + @DadTellPhon + N'%')  
  AND (@SuntCode IS NULL OR @SuntCode = '' OR F.SUNT_CODE_DNRM = @SuntCode)
)
GO
