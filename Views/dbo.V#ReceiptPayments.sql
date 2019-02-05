SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[V#ReceiptPayments]
AS
SELECT  dbo.Request.RQID ,
        dbo.GET_MTOS_U(dbo.Request.RQST_DATE) AS RQST_DATE ,
        --dbo.Request.YEAR ,        
        dbo.V#Users.USER_NAME AS CRET_BY ,
        dbo.Request_Type.RQTP_DESC ,
        dbo.Requester_Type.RQTT_DESC ,
        dbo.Method.MTOD_DESC ,
        dbo.Category_Belt.CTGY_DESC ,
        dbo.D$SXTP.DOMN_DESC AS SXTP ,
        dbo.D$RQST.DOMN_DESC AS RQST ,
        dbo.Club.NAME ,
        dbo.Club_Method.STRT_TIME ,
        dbo.Club_Method.END_TIME ,
        dbo.D$DYTP.DOMN_DESC AS DYTP ,
        dbo.Payment_Method.AMNT ,
        dbo.D$RCMT.DOMN_DESC AS RCMT ,
        dbo.GET_MTOS_U(dbo.Payment_Method.ACTN_DATE) AS ACTN_DATE ,
        SUBSTRING(dbo.GET_MTOS_U(dbo.Payment_Method.ACTN_DATE), 1, 4) AS YEAR ,
        SUBSTRING(dbo.GET_MTOS_U(dbo.Payment_Method.ACTN_DATE), 6, 2) AS CYCL ,
        dbo.D$CYCL.DOMN_DESC AS CYCL_DESC ,
        dbo.Request_Type.CODE AS RQTP_CODE ,
        dbo.Requester_Type.CODE AS RQTT_CODE
FROM    dbo.Request_Type
        INNER JOIN dbo.Request_Row
        INNER JOIN dbo.Request ON dbo.Request_Row.RQST_RQID = dbo.Request.RQID
        INNER JOIN dbo.Requester_Type ON dbo.Request.RQTT_CODE = dbo.Requester_Type.CODE ON dbo.Request_Type.CODE = dbo.Request.RQTP_CODE
        INNER JOIN dbo.Fighter ON dbo.Request_Row.FIGH_FILE_NO = dbo.Fighter.FILE_NO
        INNER JOIN dbo.Category_Belt ON dbo.Fighter.CTGY_CODE_DNRM = dbo.Category_Belt.CODE
        INNER JOIN dbo.Method ON dbo.Category_Belt.MTOD_CODE = dbo.Method.CODE
        INNER JOIN dbo.D$SXTP ON dbo.Fighter.SEX_TYPE_DNRM = dbo.D$SXTP.VALU
        INNER JOIN dbo.D$RQST ON dbo.Request.RQST_STAT = dbo.D$RQST.VALU
        INNER JOIN dbo.V#Users ON dbo.Request.CRET_BY = dbo.V#Users.USER_DB
        INNER JOIN dbo.Club_Method ON dbo.Fighter.CBMT_CODE_DNRM = dbo.Club_Method.CODE
        INNER JOIN dbo.Club ON dbo.Club_Method.CLUB_CODE = dbo.Club.CODE
        INNER JOIN dbo.D$DYTP ON dbo.Club_Method.DAY_TYPE = dbo.D$DYTP.VALU
        INNER JOIN dbo.Payment_Method ON dbo.Request_Row.RQST_RQID = dbo.Payment_Method.RQRO_RQST_RQID
                                         AND dbo.Request_Row.RWNO = dbo.Payment_Method.RQRO_RWNO AND dbo.Payment_Method.RCPT_MTOD NOT IN ('005')
        INNER JOIN dbo.D$RCMT ON dbo.Payment_Method.RCPT_MTOD = dbo.D$RCMT.VALU
        INNER JOIN dbo.D$CYCL ON ('0' + SUBSTRING(dbo.GET_MTOS_U(dbo.Payment_Method.ACTN_DATE), 6, 2)) = dbo.D$CYCL.VALU
WHERE   ( dbo.Request.RQST_STAT = '001' )
        OR ( dbo.Request.RQST_STAT = '002' );


GO
EXEC sp_addextendedproperty N'MS_DiagramPane1', N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1[34] 4[30] 3) )"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1[56] 3) )"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3) )"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 1
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "Request_Type"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 160
               Right = 249
            End
            DisplayFlags = 280
            TopColumn = 1
         End
         Begin Table = "Request_Row"
            Begin Extent = 
               Top = 102
               Left = 572
               Bottom = 256
               Right = 829
            End
            DisplayFlags = 344
            TopColumn = 2
         End
         Begin Table = "Request"
            Begin Extent = 
               Top = 104
               Left = 166
               Bottom = 258
               Right = 423
            End
            DisplayFlags = 344
            TopColumn = 0
         End
         Begin Table = "Requester_Type"
            Begin Extent = 
               Top = 7
               Left = 339
               Bottom = 161
               Right = 527
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Fighter"
            Begin Extent = 
               Top = 355
               Left = 857
               Bottom = 509
               Right = 1210
            End
            DisplayFlags = 344
            TopColumn = 0
         End
         Begin Table = "Category_Belt"
            Begin Extent = 
               Top = 354
               Left = 499
               Bottom = 508
               Right = 747
            End
            DisplayFlags = 344
            TopColumn = 0
         End
         Begin Table = "Method"
            Begin Extent = 
               Top = 347
               Left = 237
               Bottom = 501
               Right = 425
            End
       ', 'SCHEMA', N'dbo', 'VIEW', N'V#ReceiptPayments', NULL, NULL
GO
EXEC sp_addextendedproperty N'MS_DiagramPane2', N'     DisplayFlags = 344
            TopColumn = 0
         End
         Begin Table = "D$SXTP"
            Begin Extent = 
               Top = 471
               Left = 952
               Bottom = 581
               Right = 1140
            End
            DisplayFlags = 344
            TopColumn = 0
         End
         Begin Table = "D$RQST"
            Begin Extent = 
               Top = 161
               Left = 461
               Bottom = 271
               Right = 649
            End
            DisplayFlags = 344
            TopColumn = 0
         End
         Begin Table = "D$CYCL"
            Begin Extent = 
               Top = 183
               Left = 1
               Bottom = 293
               Right = 189
            End
            DisplayFlags = 344
            TopColumn = 0
         End
         Begin Table = "V#Users"
            Begin Extent = 
               Top = 43
               Left = 577
               Bottom = 153
               Right = 765
            End
            DisplayFlags = 344
            TopColumn = 0
         End
         Begin Table = "Club_Method"
            Begin Extent = 
               Top = 697
               Left = 591
               Bottom = 851
               Right = 780
            End
            DisplayFlags = 344
            TopColumn = 0
         End
         Begin Table = "Club"
            Begin Extent = 
               Top = 694
               Left = 235
               Bottom = 848
               Right = 492
            End
            DisplayFlags = 344
            TopColumn = 3
         End
         Begin Table = "D$DYTP"
            Begin Extent = 
               Top = 667
               Left = 864
               Bottom = 777
               Right = 1052
            End
            DisplayFlags = 344
            TopColumn = 0
         End
         Begin Table = "Payment_Method"
            Begin Extent = 
               Top = 92
               Left = 902
               Bottom = 246
               Right = 1117
            End
            DisplayFlags = 280
            TopColumn = 12
         End
         Begin Table = "D$RCMT"
            Begin Extent = 
               Top = 171
               Left = 1135
               Bottom = 281
               Right = 1323
            End
            DisplayFlags = 344
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
      PaneHidden = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 19
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 3000
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
', 'SCHEMA', N'dbo', 'VIEW', N'V#ReceiptPayments', NULL, NULL
GO
DECLARE @xp int
SELECT @xp=2
EXEC sp_addextendedproperty N'MS_DiagramPaneCount', @xp, 'SCHEMA', N'dbo', 'VIEW', N'V#ReceiptPayments', NULL, NULL
GO
