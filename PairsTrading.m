% �����PAIRnewnew,���ĵĵط�����,����Ʊʱ,������ȸĳ������ֵ�������,��lembda�����õĶ�̬lambda,���Ǿ�̬lambda
HS300_advanced=(xlsread('������ȯ�����֤800��������.xlsx','��ʷ����'))';
[CLOSE,txt]=xlsread('������ȯ�������.xlsx','sheet1');%�ɷֹ����̼�
[~,STIU]=xlsread('���ʱ�Ĺ�Ʊ����״̬.xlsx','��ʷ����');
STIU=STIU';
STIU=STIU(2:end,5:end);
[~,ll]=find(cellfun('isempty',STIU)==1,1,'first');
STIU=STIU(:,1:ll-1);
[aa,bb]=size(STIU);
STIUATION=ones(aa,bb).*9999;
for i=1:aa
    for j=1:bb
        if strcmp(STIU{i,j},'��������')||strcmp(STIU{i,j},'����')||strcmp(STIU{i,j},'����ͣ��')||strcmp(STIU{i,j},'ͣ��һСʱ')||strcmp(STIU{i,j},'ͣ�ư���')||strcmp(STIU{i,j},'ͣ�ư�Сʱ')
            STIUATION(i,j)=1;
        elseif strcmp(STIU{i,j},'��ͣ����')||strcmp(STIU{i,j},'����ͣ��')||strcmp(STIU{i,j},'ͣ��һ��')||strcmp(STIU{i,j},'δ����')
            STIUATION(i,j)=0;
        end
    end
end
xlswrite('C:\csvdata\Pair_STIUATION.xlsx', STIUATION ,'sheet1')
OPEN=(xlsread('������ȯ��Ŀ���.xlsx','sheet1'))';
CLOSE(isnan(CLOSE))=0;
CLOSE=CLOSE';
%��׼���۸�
% r(i)=log(p(i))-log(p(i-1))
% SP(t)��ʾ��t��ı�׼�۸�,SP(t)=sum(1+r(i):i=1~t)
LOGreturn=LOGreturn_maker(CLOSE);
LOGreturn(isnan(LOGreturn))=0;
SP=cumprod((1+LOGreturn),2);
secName=txt(3,2:end)';
tradeDate=txt(5:end,1)';%��Ʊ�����б�,������
tradeDate=tradeDate(1:find(cellfun('isempty',tradeDate)==1,1,'first')-1);
tradeDate=tradeDate(1,1:end);
OPEN(isnan(OPEN))=0;
% load('PAIRnewnew.mat')
%----------------------------------------------------------------------------��������
%----------------------------------------------------------------------------�����˻���Ϣ
Observe=220;
TOP=500;
storageRoom=5;
stamptax_rate=0.001;    
commision_rate=0.00025;
lowest_commision=5;
pre_pairNumber=80;
pairNumber=40;
confidence_coeff=3;
changeMonth=3;
Loanthreshhold=0.2;%��ȯƽ��ֹ���
%Observe=480
%storagerRoom=15
%---------------------------------------------------------------------------�˻���Ϣ�������
OPEN=OPEN(1:TOP,:);
secName=secName(1:TOP,:);
CLOSE=CLOSE(1:TOP,:);
STIUATION=STIUATION(1:TOP,:);
[s,row]=size(CLOSE);
capital=zeros(1,row);
Loan_capital=zeros(1,row);
cash=zeros(1,row);
cash(1,1:Observe)=200000;
universe=cell(pairNumber,length(tradeDate));

benchmarkCLOSE=HS300_advanced(4,:);%��Ӧָ�����̼�
benchmarkOPEN=HS300_advanced(1,:);%��Ӧָ�����̼�
storage=zeros(storageRoom,row);%���ǹ�Ʊ,����ʱ��,�м����ֵ�ǹ�Ʊ��λ��
storage_Loan=zeros(storageRoom,row);%��ȯ�Ĳ�λ ��Ĺ�Ʊ��storage��,�ڵ�ȯ��storage_Loan��
each_lamda=zeros(s,row);
buy_record=cell(storageRoom,row);
sale_record=cell(storageRoom,row);
buyLoan_record=cell(storageRoom,row);
saleLoan_record=cell(storageRoom,row);
%----------------------------��ȯ���
buyLoan=zeros(s,row);
saleLoan=zeros(s,row);
%----------------------------��ȯ���
Condition=zeros(s,row);
storage_name=cell(size(storage));
storage_Loan_name=cell(size(storage));
buy=zeros(s,row);
secLoanValue=zeros(s,row);
sale=zeros(s,row);
volume=zeros(s,row);%s,row��CLOSE���к���
Loan_volume=zeros(s,row);
perreturn=zeros(s,row);
perreturn_rate=zeros(s,row);
dayreturn=zeros(1,row);
stamptax=zeros(s,row);%ӡ��˰,����ʱ�����ȡ
buy_commision=zeros(s,row);%Ӷ��,��������ȡ,Ӷ������Сֵlowest_commision
sale_commision=zeros(s,row);

benchmark_rt=(benchmarkCLOSE(1,Observe+1:end)-benchmarkOPEN(1,Observe+1))./benchmarkOPEN(1,Observe+1);
for Date=Observe:(length(tradeDate)-1)%ѭ��ÿ��
    xc=Date
    histwindow=120;
%-------------------------------------------����ÿ���˻���Ϣ
    storage_name(:,Date+1)=storage_name(:,Date);
    storage_Loan_name(:,Date+1)=storage_Loan_name(:,Date);
    storage(:,Date+1)=storage(:,Date);
    storage_Loan(:,Date+1)=storage_Loan(:,Date);
    volume(:,Date+1)=volume(:,Date);
    Loan_volume(:,Date+1)=Loan_volume(:,Date);
    cash(1,Date+1)=cash(1,Date);
    secLoanValue(:,Date+1)=secLoanValue(:,Date);

    universe(:,Date+1)=universe(:,Date);
%--------------------------------------------�������

%----------------------------------------------������Ʊ��
    if mod(Date-Observe,20.*changeMonth)==0%��Ϊ��λ���¹�Ʊ��
        today=tradeDate(1,Date);
%         distance=ones(length(secName),length(secName)).*10000000;
%         distance_origin=ones(length(secName),length(secName)).*10000000;
        distance=ones(length(secName),length(secName)).*inf;
        distance_origin=ones(length(secName),length(secName)).*inf;
        universe(:,Date+1)=cell(pairNumber,1);
 %---------------------------------------------ѡȡ������С��
        for i=1:length(secName)-1
            for j=i+1:length(secName)%����ÿһ�Թ�Ʊ�ľ���
                temp1=SP(i,Date-histwindow:Date)-SP(j,Date-histwindow:Date);
                temp2=power(temp1,2);
                temp3=sum(temp2);%����涨ʱ�䴰����,������׼���Ժ�Ĺ�Ʊ�۸�ʱ�����е���С���˷��еľ���
                distance(i,j)=temp3;
                distance_origin(i,j)=temp3;
            end
            if prod(SP(i,1:Date))==1%���û����
                distance(i,:)=inf;
                distance(:,i)=inf;
                distance_origin(i,:)=inf;
                distance_origin(:,i)=inf;
                %����Ʊû������,��������֮���
            end
        end%universe=cell(pairNumber,length(tradeDate));
        preuniverse=zeros(pre_pairNumber,2);%����ɸѡ��������С��
        for i=1:pre_pairNumber
            [a,b]=find(distance==min(min(distance)),1,'last');
            preuniverse(i,:)=[a,b];
            distance(a,:)=inf;
            distance(:,a)=inf;
            distance(:,b)=inf;
            distance(b,:)=inf;
        end
        adfuniverse=[];%���ҳ��ľ���С��������ҳ���ƽ��ʱ�����е����(ͨ��adftest�����)
        for j=1:pre_pairNumber
            A=SP(preuniverse(j,1),Date-histwindow:Date);
            B=SP(preuniverse(j,2),Date-histwindow:Date);
            for c=1:length(A)                        
                h1=adftest(A);
                h2=adftest(B);
                if h1==1&&h2==1
                    adfuniverse=[adfuniverse;preuniverse(j,:)];
                    break;
                elseif h1==0&&h2==0
                    A=diff(A);
                    B=diff(B);
                    if sum(A)==0||sum(5)==0
                        %�����й�Ʊ��ʱ������ͣ��
                        break;
                    end
                elseif (~(h1==1&&h2==1))&&(h1==1||h2==1)
                    break;
                end
            end            
        end

        for i=1:length(adfuniverse)%����ѡ���ľ���ƽ��ʱ�����е������Э������,�ҳ�����Э��ЧӦ�����
            y=[(SP(adfuniverse(i,1),Date-histwindow:Date))',(SP(adfuniverse(i,2),Date-histwindow:Date))'];
            h=egcitest(y);
            nullloc=cellfun('isempty',universe(:,Date+1)); %universe��cell,cellfun��cellfunction����˼
            null_first=find(nullloc==1,1,'first');%=1Ϊ��
            if length(find(nullloc==1))>0
                if h==1
                    universe{null_first,Date+1}=adfuniverse(i,:);
                end
            else
                break;
            end
        end
    end
%------------------------------------------------������Ʊ�����
%-----------------------------------------------�����ź�   
    for p=1:storageRoom
        if  storage(p,Date+1)~=0&&storage_Loan(p,Date+1)~=0
            %ÿ�Ե�һ������,�ڶ�������
            mai=storage(p,Date+1);
            rong=storage_Loan(p,Date+1);
            
            STOPprice=round(CLOSE(mai,Date).*1.1.*100)./100;
            STOPDprice=round(CLOSE(mai,Date).*0.9.*100)./100;
            STOPLoanprice=round(CLOSE(rong,Date).*1.1.*100)./100;
            STOPLoanDprice=round(CLOSE(rong,Date).*0.9.*100)./100;
            if OPEN(rong,Date+1)<STOPLoanprice&&OPEN(rong,Date+1)>STOPLoanDprice&& OPEN(mai,Date+1)<STOPprice&&OPEN(mai,Date+1)>STOPDprice
                if STIUATION(mai,Date+1)==1&&STIUATION(rong,Date+1)==1%��ͣ��
                    buydate=find(buy(mai,:)~=0, 1, 'last' );%���һ���������
                    if Condition(mai,buydate)==1%���ʱ����ݵ���lembda_positive,����С��,���մ�� 
%                        Diff=CLOSE(rong,Date-histwindow:Date)-CLOSE(mai,Date-histwindow:Date);
                        lemda=each_lamda(mai,buydate);%mean(Diff)+confidence_coeff.*std(Diff);                            
                        if CLOSE(rong,Date)-CLOSE(mai,Date)<lemda||(-(Loan_volume(rong,buydate).*(OPEN(rong,buydate)-OPEN(rong,Date+1)))./(Loan_volume(rong,buydate).*OPEN(rong,buydate)))>=Loanthreshhold
                    %����������,����С��
                            sale_commision(mai,Date+1)=(volume(mai,buydate).*OPEN(mai,Date+1)).*commision_rate;
                            if sale_commision(mai,Date+1)<lowest_commision                           
                                sale_commision(mai,Date+1)=lowest_commision;
                            end
                            stamptax(mai,Date+1)=(volume(mai,buydate).*OPEN(mai,Date+1)).*stamptax_rate;
                            cash(1,Date+1)=cash(1,Date+1)+volume(mai,buydate).*OPEN(mai,Date+1)-stamptax(mai,Date+1)-sale_commision(mai,Date+1);                        
                            sale(mai,Date+1)=OPEN(mai,Date+1);
                            sale_record(p,Date+1)=secName(mai,1);

                      %���������Ĵ��
                            saleLoan(rong,Date+1)=OPEN(rong,Date+1);
                            sale_commision(rong,Date+1)=(Loan_volume(rong,buydate).*OPEN(rong,Date+1)).*commision_rate;
                            if sale_commision(rong,Date+1)<lowest_commision                           
                                sale_commision(rong,Date+1)=lowest_commision;
                            end
                            stamptax(rong,Date+1)=(Loan_volume(rong,buydate).*OPEN(rong,Date+1)).*stamptax_rate; 
                            temp=Loan_volume(rong,buydate).*(OPEN(rong,buydate)-OPEN(rong,Date+1))- stamptax(rong,Date+1)-sale_commision(rong,Date+1);
                            cash(1,Date+1)=cash(1,Date+1)+temp;                        
                            saleLoan_record(p,Date+1)=secName(rong,1);                       
                            perreturn(mai,Date+1)=(OPEN(mai,Date+1)-OPEN(mai,buydate)).*volume(mai,buydate)-stamptax(mai,Date+1)-sale_commision(mai,Date+1)-buy_commision(mai,buydate)+temp;
                            perreturn_rate(mai,Date+1)=perreturn(mai,Date+1)./(volume(mai,buydate).*OPEN(mai,buydate)+buy_commision(mai,buydate));
                            %���¾�����Ϣ
                            volume(mai,Date+1)=0;
                            volume(rong,Date+1)=0;
                            storage(p,Date+1)=0;
                            storage_name{p,Date+1}=[];
                            storage_Loan(p,Date+1)=0;
                            storage_Loan_name{p,Date+1}=[];
                        end
                    elseif Condition(mai,buydate)==2%���ʱ���Ǹ���lemda_negative
                        %������,����С��
                        %ÿ�Ե�һ��Ϊ��,�ڶ���Ϊ��,Ҳ����˵��condition2��,��һ���Ǵ�,�ڶ�����С
%                         Diff=CLOSE(mai,Date-histwindow:Date)-CLOSE(rong,Date-histwindow:Date);
%                         lemda=mean(Diff);
                        lemda=each_lamda(mai,buydate);%mean(Diff)-confidence_coeff.*std(Diff);                            
                        if CLOSE(mai,Date)-CLOSE(rong,Date)>lemda||(-(Loan_volume(rong,buydate).*(OPEN(rong,buydate)-OPEN(rong,Date+1)))./(Loan_volume(rong,buydate).*OPEN(rong,buydate)))>=Loanthreshhold
                    %����������,�������
                            sale_commision(mai,Date+1)=(volume(mai,buydate).*OPEN(mai,Date+1)).*commision_rate;
                            if sale_commision(mai,Date+1)<lowest_commision                           
                                sale_commision(mai,Date+1)=lowest_commision;
                            end
                            stamptax(mai,Date+1)=(volume(mai,buydate).*OPEN(mai,Date+1)).*stamptax_rate;
                            cash(1,Date+1)=cash(1,Date+1)+volume(mai,buydate).*OPEN(mai,Date+1)-stamptax(mai,Date+1)-sale_commision(mai,Date+1);                       
                            sale(mai,Date+1)=OPEN(mai,Date+1);
                            sale_record(p,Date+1)=secName(mai,1);

                      %����������С��
                            saleLoan(rong,Date+1)=OPEN(rong,Date+1);
                            sale_commision(rong,Date+1)=(volume(rong,buydate).*OPEN(rong,Date+1)).*commision_rate;
                            if sale_commision(rong,Date+1)<lowest_commision                           
                                sale_commision(rong,Date+1)=lowest_commision;

                            end
                            stamptax(rong,Date+1)=(Loan_volume(rong,buydate).*OPEN(rong,Date+1)).*stamptax_rate; 
                            temp=Loan_volume(rong,buydate).*(OPEN(rong,buydate)-OPEN(rong,Date+1))- stamptax(rong,Date+1)-sale_commision(rong,Date+1);
                            cash(1,Date+1)=cash(1,Date+1)+temp;                        
                            saleLoan_record(p,Date+1)=secName(rong,1);
                            perreturn(mai,Date+1)=(OPEN(mai,Date+1)-OPEN(mai,buydate)).*volume(mai,buydate)-stamptax(mai,Date+1)-sale_commision(mai,Date+1)-buy_commision(mai,buydate)+temp;
                            perreturn_rate(mai,Date+1)=perreturn(mai,Date+1)./(volume(mai,buydate).*OPEN(mai,buydate)+buy_commision(mai,buydate));
                            %���¾�����Ϣ
                            volume(mai,Date+1)=0;
                            volume(rong,Date+1)=0;
                            storage(p,Date+1)=0;
                            storage_name{p,Date+1}=[];
                            storage_Loan(p,Date+1)=0;
                            storage_Loan_name{p,Date+1}=[];

                        end
                    end
                end
            end

        end
    end
%-----------------------------------------------------------------�����ź�       
    for pair=1:pairNumber%����universe�����е����  
        nullloc=cellfun('isempty',universe(pair,Date+1));
        if nullloc==0%ȷ��Ԫ����Ϊ��
%--------------------------------------------------------------------------------------------�����ź�
            first=universe{pair,Date+1}(1,1);
            second=universe{pair,Date+1}(1,2);

            if length(find(storage(:,Date+1)~=first))==storageRoom&&length(find(storage_Loan(:,Date+1)~=first))==storageRoom %��Ĺ�Ʊû�гֲ�
                if length(find(storage_Loan(:,Date+1)~=second))==storageRoom&&length(find(storage(:,Date+1)~=second))==storageRoom %�ڵĹ�Ʊû�гֲ�
                    if length(find(storage(:,Date+1)==0))>0%������ڻ��й�Ʊ         
                            STOPprice=round(CLOSE(first,Date).*1.1.*100)./100;
                            STOPDprice=round(CLOSE(first,Date).*0.9.*100)./100;
                            STOPLoanprice=round(CLOSE(second,Date).*1.1.*100)./100;
                            STOPLoanDprice=round(CLOSE(second,Date).*0.9.*100)./100;
                            if OPEN(first,Date+1)<STOPprice&&OPEN(first,Date+1)>STOPDprice&&OPEN(second,Date+1)<STOPLoanprice&&OPEN(second,Date+1)>STOPLoanDprice%�ж��Ƿ���ͣ
                                if STIUATION(first,Date+1)==1&&STIUATION(second,Date+1)==1%�жϸöԹ�Ʊ�Ƿ���Խ��н���,������������һ�����ܽ���,��ȫ�����ܽ���
                                    
                                   CLOSEseries=[mean(CLOSE(first,1:Date)),mean(CLOSE(second,1:Date))];
                                   pos_bigger=find(CLOSEseries==max(CLOSEseries));
                                   pos_smaller=find(CLOSEseries==min(CLOSEseries));

                                   bigger=universe{pair,Date+1}(1,pos_bigger);
                                   smaller=universe{pair,Date+1}(1,pos_smaller);

                                   Diff=CLOSE(bigger,Date-histwindow:Date)-CLOSE(smaller,Date-histwindow:Date);
                                   lemda_positive=mean(Diff)+confidence_coeff.*std(Diff);
                                   lemda_negative=mean(Diff)-confidence_coeff.*std(Diff);
                                   if CLOSE(bigger,Date)-CLOSE(smaller,Date)>lemda_positive
                                       %���մ��,����С��
                                       each_lamda(smaller,Date+1)=mean(Diff);%+std(Diff);
            %-----------------------------------------------------------------------------------------------����С��
                                        volume(smaller,Date+1)=cash(1,Date+1)./(length(find(storage(:,Date+1)==0)).*OPEN(smaller,Date+1)); 
            %-----------------------------------------------------------------------------------------------���������� 
                                        volume(smaller,Date+1)=HSLsec_Advanced_Limit_test_round(volume(smaller,Date+1),100);
            %-----------------------------------------------------------------------------------------------���ʱ����뿼���ʽ����
                                        [volume(smaller,Date+1),buy_commision(smaller,Date+1)]=HSLsec_Advanced_Limit_account_limit(cash(1,Date+1),volume(smaller,Date+1),OPEN(smaller,Date+1),commision_rate);
            %----------------------------------------------------------------------------------------------------------------------------------------------------------------- 
                                        tradeValue=volume(smaller,Date+1).*OPEN(smaller,Date+1);
                                        cash(1,Date+1)=cash(1,Date+1)-tradeValue-buy_commision(smaller,Date+1);
                                        if volume(smaller,Date+1)~=0
                                            buy(smaller,Date+1)=OPEN(smaller,Date+1);
                                            b=find(storage(:,Date+1)==0, 1 ,'first');
                                            storage(b,Date+1)=smaller;
                                            storage_name(b,Date+1)=secName(smaller,1);
                                            buy_record(b,Date+1)=secName(smaller,1);
                                            Condition(smaller,Date+1)=1;
                                            Condition(bigger,Date+1)=1;
                                        end 
            %---------------------------------------------------------------------------------���մ��
                                        Loan_volume(bigger,Date+1)=tradeValue./OPEN(bigger,Date+1);
                                        Loan_volume(bigger,Date+1)=HSLsec_Advanced_Limit_test_round(Loan_volume(bigger,Date+1),100);
                                        
                            %            Loan_volume(bigger,Date+1)=volume(smaller,Date+1);
                                        if Loan_volume(bigger,Date+1)~=0
                                            buyLoan(bigger,Date+1)=OPEN(bigger,Date+1);
                                            secLoanValue(bigger,Date+1)=OPEN(bigger,Date+1).*Loan_volume(bigger,Date+1);
                                            b=find(storage_Loan(:,Date+1)==0, 1 ,'first');
                                            storage_Loan(b,Date+1)=bigger;
                                            storage_Loan_name(b,Date+1)=secName(bigger,1);
                                            buyLoan_record(b,Date+1)=secName(bigger,1);
                                        end
                                   elseif CLOSE(bigger,Date)-CLOSE(smaller,Date)<lemda_negative
                                       %������,����С��
                                       each_lamda(bigger,Date+1)=mean(Diff);%-std(Diff);
            %-------------------------------------------------------------------------------------------------------------------------------------------������
                                        volume(bigger,Date+1)=cash(1,Date+1)./(length(find(storage(:,Date+1)==0)).*OPEN(bigger,Date+1)); 
            %-----------------------------------------------------------------------------------------------------------------------------------------���������� 
                                        volume(bigger,Date+1)=HSLsec_Advanced_Limit_test_round(volume(bigger,Date+1),100);
            %------------------------------------------------------------------------------------------------------------------------------------------���ʱ����뿼���ʽ����
                                        [volume(bigger,Date+1),buy_commision(bigger,Date+1)]=HSLsec_Advanced_Limit_account_limit(cash(1,Date+1),volume(bigger,Date+1),OPEN(bigger,Date+1),commision_rate);
            %-----------------------------------------------------------------------------------------------------------------------------------------------------------------
                                        tradeValue=volume(bigger,Date+1).*OPEN(bigger,Date+1);
                                        cash(1,Date+1)=cash(1,Date+1)-tradeValue-buy_commision(bigger,Date+1);
                                        if volume(bigger,Date+1)~=0
                                            buy(bigger,Date+1)=OPEN(bigger,Date+1);
                                            b=find(storage(:,Date+1)==0, 1 );
                                            storage(b,Date+1)=bigger;
                                            storage_name(b,Date+1)=secName(bigger,1);
                                            buy_record(b,Date+1)=secName(bigger,1);
                                            Condition(smaller,Date+1)=2;
                                            Condition(bigger,Date+1)=2;
                                        end 
            %--------------------------------------------------------------------------------------------------------------------------------����С��
                                        Loan_volume(smaller,Date+1)=tradeValue./OPEN(smaller,Date+1);
                                        Loan_volume(smaller,Date+1)=HSLsec_Advanced_Limit_test_round(Loan_volume(smaller,Date+1),100);
                                        if Loan_volume(smaller,Date+1)~=0
                                            buyLoan(smaller,Date+1)=OPEN(smaller,Date+1);
                   %                        
                                            secLoanValue(smaller,Date+1)=OPEN(smaller,Date+1).*Loan_volume(smaller,Date+1);
                                            b=find(storage_Loan(:,Date+1)==0, 1,'first' );
                                            storage_Loan(b,Date+1)=smaller;
                                            storage_Loan_name(b,Date+1)=secName(smaller,1);
                                            buyLoan_record(b,Date+1)=secName(smaller,1);
                                        end 
                                   end
                                end
                            end

                    else
                        break;
                    end
                else
                    continue;
                end
            end
        end
    end
    %--------------------------------------------ÿ������

    %--------------------------------------------����ÿһ���ʲ��۸� 

        for i=1:length(storage(:,Date+1))
            if storage(i,Date+1)~=0

                capital(1,Date+1)=capital(1,Date+1)+volume(storage(i,Date+1),Date+1).*CLOSE(storage(i,Date+1),Date+1);
            end
        end
        for i=1:length(storage_Loan(:,Date+1))
            if storage_Loan(i,Date+1)~=0
                buydate=find(buyLoan(storage_Loan(i,Date+1),1:Date+1)~=0, 1, 'last' );
                temp=Loan_volume(storage_Loan(i,Date+1),buydate).*(OPEN(storage_Loan(i,Date+1),buydate)-CLOSE(storage_Loan(i,Date+1),Date+1));
                Loan_capital(1,Date+1)=Loan_capital(1,Date+1)+temp;
            end
        end
  
    
%--------------------------------------------�������
end

accountValue=cash+capital+Loan_capital;
account_rt=(accountValue-cash(1,1))./cash(1,1);
[a,b]=find(perreturn_rate~=0);
pertrade=[];
for i=1:length(a)
    pertrade=[pertrade,perreturn_rate(a(i),b(i))];
end
A_result_perDay_rt=diff(accountValue(1,Observe+1:end))./accountValue(1,Observe+1:end-1);
A_result_Annual_sharp=(mean(A_result_perDay_rt)./std(A_result_perDay_rt)).*16;
%---------------------------------------------���ӹ�
win=length(find(pertrade>0))./length(pertrade);
maxday=find(account_rt==max(account_rt),1);
[bloc,floc,maxDrawDown]=maxdrawdown_maker(accountValue(Observe:end));%(max(accountValue)-min(accountValue(maxday:end)))./max(accountValue);
AnnualYeild=account_rt(length(account_rt))./length(tradeDate(Observe:end)).*250;
[a,b]=size(buy(:,Observe:end));
A_result_buy=cell(a+1,b+1);
A_result_buy(2:a+1,2:b+1)=num2cell(buy(:,Observe:end));
A_result_buy(1,2:b+1)=tradeDate(Observe:end);
A_result_buy(2:a+1,1)=secName;

A_result_sale=cell(a+1,b+1);
A_result_sale(2:a+1,2:b+1)=num2cell(sale(:,Observe:end));
A_result_sale(1,2:b+1)=tradeDate(Observe:end);
A_result_sale(2:a+1,1)=secName;

A_result_buy_commision=cell(a+1,b+1);
A_result_buy_commision(2:a+1,2:b+1)=num2cell(buy_commision(:,Observe:end));
A_result_buy_commision(1,2:b+1)=tradeDate(Observe:end);
A_result_buy_commision(2:a+1,1)=secName;
total_buyCom=sum(sum(sparse(buy_commision)));

A_result_sale_commision=cell(a+1,b+1);
A_result_sale_commision(2:a+1,2:b+1)=num2cell(sale_commision(:,Observe:end));
A_result_sale_commision(1,2:b+1)=tradeDate(Observe:end);
A_result_sale_commision(2:a+1,1)=secName;
total_saleCom=sum(sum(sparse(sale_commision)));

total_commision=total_saleCom+total_buyCom;

A_result_stamptax=cell(a+1,b+1);
A_result_stamptax(2:a+1,2:b+1)=num2cell(stamptax(:,Observe:end));
A_result_stamptax(1,2:b+1)=tradeDate(Observe:end);
A_result_stamptax(2:a+1,1)=secName;
total_stp=sum(sum(sparse(stamptax)));

total_extraspend=total_stp+total_commision;

A_result_volume=cell(a+1,b+1);
A_result_volume(2:a+1,2:b+1)=num2cell(volume(:,Observe:end));
A_result_volume(1,2:b+1)=tradeDate(Observe:end);
A_result_volume(2:a+1,1)=secName;

[c,d]=size(storage);
A_result_storage=cell(c+1,d);
A_result_storage(1,:)=tradeDate;
A_result_storage(2:c+1,:)=storage_name;
A_result_storage=A_result_storage(:,Observe:end);
A_result_buy_record=cell(c+1,d);
A_result_buy_record(1,:)=tradeDate;
A_result_buy_record(2:c+1,:)=buy_record;
A_result_buy_record=A_result_buy_record(:,Observe:end);
A_result_sale_record=cell(c+1,d);
A_result_sale_record(1,:)=tradeDate;
A_result_sale_record(2:c+1,:)=sale_record;
A_result_sale_record=A_result_sale_record(:,Observe:end);


[e,f]=size(account_rt(Observe:end));
A_result_accountRt=cell(e+1,f);
A_result_accountRt(1,:)=tradeDate(Observe:end);
A_result_accountRt(2,:)=num2cell(account_rt(Observe:end));
A_result_accountValue=cell(e+1,f);
A_result_accountValue(1,:)=tradeDate(Observe:end);
A_result_accountValue(2,:)=num2cell(accountValue(Observe:end));

A_result_dayreturn=cell(e+1,f);
A_result_dayreturn(1,:)=tradeDate(Observe:end);
A_result_dayreturn(2,:)=num2cell(dayreturn(Observe:end));

A_result_cash=cell(e+1,f);
A_result_cash(1,:)=tradeDate(Observe:end);
A_result_cash(2,:)=num2cell(cash(Observe:end));
A_result_capital=cell(e+1,f);
A_result_capital(1,:)=tradeDate(Observe:end);
A_result_capital(2,:)=num2cell(capital(Observe:end));

[g,h]=size(CLOSE);
A_result_CLOSE=cell(g+1,h+1);
A_result_CLOSE(2:g+1,2:h+1)=num2cell(CLOSE);
A_result_CLOSE(1,2:h+1)=tradeDate(1:end);
A_result_CLOSE(2:g+1,1)=secName;

[j,k]=size(OPEN);
A_result_OPEN=cell(j+1,k+1);
A_result_OPEN(2:j+1,2:k+1)=num2cell(OPEN);
A_result_OPEN(1,2:k+1)=tradeDate;
A_result_OPEN(2:j+1,1)=secName;
A_result_STIUATION=cell(j+1,k+1);
A_result_STIUATION(2:j+1,2:k+1)=num2cell(STIUATION);
A_result_STIUATION(1,2:k+1)=tradeDate;
A_result_STIUATION(2:j+1,1)=secName;


%----------------------------------------------���ӹ�����

%----------------------------------------------���ӻ����ֹ���
figure(1)
subplot(2,1,1)
hold on 
temp=account_rt(Observe:end);
plot(temp)
plot(benchmark_rt)
plot(bloc:floc,temp(bloc:floc),'r','LineWidth',4)
hold off
title('Strategy Cumulative Return')
xlabel('time')
ylabel('The Rate of Return')
legend('The Rate of Return of Strategy','The Rate of Return of Index','The Time Slot that the MaxDrawback happened')
subplot(2,1,2)
hist(pertrade,100);
[f,xout]=hist(pertrade,100);
hist_high=linspace(max(f).*(1/5),max(f).*(4/5),6);
mean_per_trade=mean(pertrade);
std_trade=std(pertrade);
title('The Return of Every Transaction') 
xlabel('The Rate of Return of Every Transaction')
ylabel('Frequency')
text(xout(end-10),hist_high(6),sprintf('Annualized Rate of Return%s',strcat(num2str(AnnualYeild.*100),'%')))
text(xout(end-10),hist_high(5),sprintf('Mean of The Rate of Raturn%s',strcat(num2str(mean_per_trade.*100),'%') ))
text(xout(end-10),hist_high(4),sprintf('Variance of The Rate of Return%d',std_trade ))
text(xout(end-10),hist_high(3),sprintf('The Rate of Win%s',strcat(num2str(win.*100),'%') ))
text(xout(end-10),hist_high(2),sprintf('Max Drawdown%s',strcat(num2str(maxDrawDown.*100),'%')))
text(xout(end-10),hist_high(1),sprintf('Sharp Ratio%s',A_result_Annual_sharp))
%----------------------------------------------���ӻ����ֽ���
