SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[UPD_AODT_P]
	-- Add the parameters for the stored procedure here
    @Agop_Code BIGINT ,
    @Rwno INT ,
    @Aodt_Agop_Code BIGINT ,
    @Aodt_Rwno INT ,
    @Figh_File_No BIGINT ,
    @Rqst_Rqid BIGINT ,
    @Attn_Code BIGINT ,
    @Coch_File_No BIGINT ,
    @Rec_Stat VARCHAR(3) ,
    @Stat VARCHAR(3) ,
    @Expn_Code BIGINT ,
    @Min_Mint_Step TIME(0) ,
    @Strt_Time DATETIME ,
    @End_Time DATETIME ,
    @Expn_Pric INT ,
    @Expn_Extr_Prct INT ,
    @Cust_Name NVARCHAR(250) ,
    @Cell_Phon VARCHAR(11) ,
    @Cash_Amnt BIGINT ,
    @Pos_Amnt BIGINT ,
    @Numb INT ,
    @Aodt_Desc NVARCHAR(250),
    @Attn_Type VARCHAR(3),
    @Pyds_Amnt BIGINT,
    @Dpst_Amnt BIGINT,
    @Bcds_Code BIGINT
AS
    BEGIN
        IF @Strt_Time > @End_Time
            BEGIN
                RAISERROR(N'ساعت پایانه بازی نمی تواند از ساعت شروع کتر باشد. "اگر تاریخ عوض شده لطفا تاریخ پایان هم تنظیم کنید"', 16, 1);
            END;
   
        UPDATE  dbo.Aggregation_Operation_Detail
        SET     FIGH_FILE_NO = @Figh_File_No ,
                RQST_RQID = @Rqst_Rqid ,
                ATTN_CODE = @Attn_Code ,
                COCH_FILE_NO = @Coch_File_No ,
                REC_STAT = @Rec_Stat ,
                STAT = @Stat ,
                EXPN_CODE = @Expn_Code ,
                MIN_MINT_STEP = @Min_Mint_Step ,
                STRT_TIME = @Strt_Time ,
                END_TIME = @End_Time ,
                EXPN_PRIC = @Expn_Pric ,
                EXPN_EXTR_PRCT = @Expn_Extr_Prct ,
                CUST_NAME = @Cust_Name ,
                CELL_PHON = @Cell_Phon ,
                AODT_AGOP_CODE = @Aodt_Agop_Code ,
                AODT_RWNO = @Aodt_Rwno ,
                CASH_AMNT = ISNULL(@Cash_Amnt, 0) ,
				--,POS_AMNT = ISNULL(@Pos_Amnt, 0)                
                NUMB = ISNULL(@Numb, 1) ,
                AODT_DESC = @Aodt_Desc ,
                ATTN_TYPE = @Attn_Type ,
                PYDS_AMNT = ISNULL(@Pyds_Amnt, 0),
                DPST_AMNT = ISNULL(@Dpst_Amnt, 0),
                BCDS_CODE = @Bcds_Code
        WHERE   AGOP_CODE = @Agop_Code
                AND RWNO = @Rwno;	   
    END;
GO
