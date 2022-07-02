%% initialization
clear
close all
clc
warning off

%% data read
Function_dataname='Dataset2'; % Dateset1=jena_climate_2009_2016; 
                              % Dateset2=202206029;
data = Get_datasets(Function_dataname);
%  data=xlsread('数据.xlsx','Sheet1','A1:N252'); %%使用xlsread函数读取EXCEL中对应范围的数据即可

%输入输出数据
input=data(:,1:end-1);    %data的第一列-倒数第二列为特征指标
output=data(:,end);  %data的最后面一列为输出的指标值

N=length(output);   %全部样本数目
testNum=300;   %设定测试样本数目 默认15
trainNum=N-testNum;    %计算训练样本数目

%% 划分训练集、测试集
input_train = input(1:trainNum,:)';
output_train =output(1:trainNum)';
input_test =input(trainNum+1:trainNum+testNum,:)';
output_test =output(trainNum+1:trainNum+testNum)';

%% 数据归一化
[inputn,inputps]=mapminmax(input_train,0,1);
[outputn,outputps]=mapminmax(output_train);
inputn_test=mapminmax('apply',input_test,inputps);

%% 获取输入层节点、输出层节点个数
inputnum=size(input,2);
outputnum=size(output,2);
disp('/////////////////////////////////')
disp('神经网络结构...')
disp(['输入层的节点数为：',num2str(inputnum)])
disp(['输出层的节点数为：',num2str(outputnum)])
disp(' ')
disp('隐含层节点的确定过程...')

%确定隐含层节点个数
%采用经验公式hiddennum=sqrt(m+n)+a，m为输入层节点个数，n为输出层节点个数，a一般取为1-10之间的整数
MSE=1e+5; %初始化最小误差
for hiddennum=fix(sqrt(inputnum+outputnum))+1:fix(sqrt(inputnum+outputnum))+10
    
    %构建网络
    net=newelm(inputn,outputn,hiddennum);
    % 网络参数
    net.trainParam.epochs=1000;         % 训练次数
    net.trainParam.lr=0.01;                   % 学习速率
    net.trainParam.goal=0.000001;        % 训练目标最小误差
    % 网络训练
    net=train(net,inputn,outputn);
    an0=sim(net,inputn);  %仿真结果
    mse0=mse(outputn,an0);  %仿真的均方误差
    disp(['隐含层节点数为',num2str(hiddennum),'时，训练集的均方误差为：',num2str(mse0)])
    
    %更新最佳的隐含层节点
    if mse0<MSE
        MSE=mse0;
        hiddennum_best=hiddennum;
    end
end
disp(['最佳的隐含层节点数为：',num2str(hiddennum_best),'，相应的均方误差为：',num2str(MSE)])

%% 构建最佳隐含层节点的ELMAN神经网络
disp(' ')
disp('标准的ELMAN神经网络：')
net0=newelm(inputn,outputn,hiddennum_best,{'tansig','purelin'},'trainlm');% 建立模型

%网络参数配置
net0.trainParam.epochs=1000;         % 训练次数，这里设置为1000次
net0.trainParam.lr=0.01;                   % 学习速率，这里设置为0.01
net0.trainParam.goal=0.00001;                    % 训练目标最小误差，这里设置为0.0001
net0.trainParam.show=25;                % 显示频率，这里设置为每训练25次显示一次
net0.trainParam.mc=0.01;                 % 动量因子
net0.trainParam.min_grad=1e-6;       % 最小性能梯度
net0.trainParam.max_fail=6;               % 最高失败次数

%开始训练
net0=train(net0,inputn,outputn);

%预测
an0=sim(net0,inputn_test); %用训练好的模型进行仿真

%预测结果反归一化与误差计算
test_simu0=mapminmax('reverse',an0,outputps); %把仿真得到的数据还原为原始的数量级
%误差指标
[mae0,mse0,rmse0,mape0,error0,errorPercent0]=calc_error(output_test,test_simu0);


%% 作图
figure
plot(output_test,'b-*','linewidth',1)
hold on
plot(test_simu0,'r-v','linewidth',1,'markerfacecolor','r')
legend('真实值','ELMAN预测值')
xlabel('测试样本编号')
ylabel('指标值')
title('ELMAN神经网络预测值和真实值对比图')

figure
plot(error0,'rv-','markerfacecolor','r')
hold on
legend('ELMAN预测误差')
xlabel('测试样本编号')
ylabel('预测偏差')
title('ELMAN神经网络预测值和真实值误差对比图')

disp(' ')
disp('/////////////////////////////////')
disp('打印结果表格')
disp('样本序号     实测值      ELMAN预测值     ELMAN误差')
for i=1:testNum
    disp([i output_test(i),test_simu0(i),error0(i)])
end

