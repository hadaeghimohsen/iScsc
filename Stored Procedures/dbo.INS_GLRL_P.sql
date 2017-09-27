SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[INS_GLRL_P]
	-- Add the parameters for the stored procedure here
	@RqroRqstRqid BIGINT,
	@RqroRwno SMALLINT,
	@FighFileNo BIGINT,
	@ConfStat VARCHAR(3),
	@ChngType VARCHAR(3),
	@DebtType VARCHAR(3),
	@Amnt INT,
	@AgreDate DATETIME,
	@PaidDate DATETIME,
	@ChngResn VARCHAR(3),
	@ResnDesc NVARCHAR(250),
	@Glid BIGINT OUT
AS
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
	          AGRE_DATE ,
	          PAID_DATE ,
	          CHNG_RESN ,
	          RESN_DESC 
	        )
	VALUES  ( 0 , -- GLID - bigint
	          @RqroRqstRqid , -- RQRO_RQST_RQID - bigint
	          @RqroRwno , -- RQRO_RWNO - smallint
	          @FighFileNo , -- FIGH_FILE_NO - bigint
	          @ConfStat , -- CONF_STAT - varchar(3)
	          @ChngType , -- CHNG_TYPE - varchar(3)
	          @DebtType , -- DEBT_TYPE - varchar(3)
	          @Amnt , -- AMNT - int
	          @AgreDate , -- AGRE_DATE - datetime
	          @PaidDate , -- PAID_DATE - datetime
	          @ChngResn , -- CHNG_RESN - varchar(3)
	          @ResnDesc  -- RESN_DESC - nvarchar(250)
	        );
	        
   SELECT @Glid = GLID
     FROM dbo.Gain_Loss_Rial
    WHERE RQRO_RQST_RQID = @RqroRqstRqid
      AND RQRO_RWNO = @RqroRwno
      AND FIGH_FILE_NO = @FighFileNo
      AND CONF_STAT = @ConfStat;
END
GO
