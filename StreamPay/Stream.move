module Stream::streampay {
    use std::bcs;
    use std::error;
    use std::signer;
    use std::string::{Self, String};
    use std::vector;

    use aptos_std::event::{Self, EventHandle};
    use aptos_std::table::{Self, Table};
    use aptos_std::type_info;
    use aptos_framework::account;
    use aptos_framework::coin::{Self, Coin};
    use aptos_framework::timestamp;

    #[test_only]
    use aptos_std::debug;
    #[test_only]
    use aptos_framework::managed_coin;

    const MIN_DEPOSIT_BALANCE: u64 = 10000; // 0.0001 APT(decimals=8)
    const MIN_RATE_PER_SECOND: u64 = 1000; // 0.00000001 APT(decimals=8)
    const INIT_FEE_POINT: u8 = 250; // 2.5%

    const STREAM_HAS_PUBLISHED: u64 = 1;
    const STREAM_NOT_PUBLISHED: u64 = 2;
    const STREAM_PERMISSION_DENIED: u64 = 3;
    const STREAM_INSUFFICIENT_BALANCES: u64 = 4;
    const STREAM_NOT_FOUND: u64 = 5;
    const STREAM_BALANCE_TOO_LITTLE: u64 = 6;
    const STREAM_HAS_REGISTERED: u64 = 7;
    const STREAM_COIN_TYPE_MISMATCH: u64 = 8;
    const STREAM_NOT_START: u64 = 9;
    const STREAM_EXCEED_STOP_TIME: u64 = 10;
    const STREAM_IS_CLOSE: u64 = 11;
    const STREAM_RATE_TOO_LITTLE: u64 = 12;
    const COIN_CONF_NOT_FOUND: u64 = 13;
    const ERR_NEW_STOP_TIME: u64 = 14;

    const EVENT_TYPE_CREATE: u8 = 0;
    const EVENT_TYPE_WITHDRAW: u8 = 1;
    const EVENT_TYPE_CLOSE: u8 = 2;
    const EVENT_TYPE_EXTEND: u8 = 3;

    const SALT: vector<u8> = b"Stream::streampay";

    /// Event emitted when created/withdraw/closed a streampay
    struct StreamEvent has drop, store {
        id: u64, // event自增 id
        coin_id: u64, // 代币(项目)内置id，方便读取和统计
        event_type: u8,
        remaining_balance: u64,
    }

    struct ConfigEvent has drop, store {
        coin_id: u64,
        fee_point: u8,
    }

    /// initialize when create
    /// change when withdraw, drop when close
    /// 每个拥有CoinType类型代币的用户都可以创建一个具有全局(对于CoinType而言)唯一的Stream
    /// 在定时触发该Stream时，修改remaining_balance的值
    struct StreamInfo has copy, drop, store {
        sender: address,
        recipient: address,
        rate_per_second: u64,
        start_time: u64,
        stop_time: u64,
        last_withdraw_time: u64,
        deposit_amount: u64, // no update

        remaining_balance: u64, // update when withdraw
        // sender_balance: u64,    // update when per second
        // recipient_balance: u64, // update when per second

    }
    
    // 托管(具体承担的角色是？)
    struct Escrow<phantom CoinType> has key {
        coin: Coin<CoinType>,
    }

    // 全局统一配置项
    struct GlobalConfig has key {
        fee_recipient: address, // 费用接收者
        admin: address, // 管理员，用以动态治理这些配置项
        coin_configs: vector<CoinConfig>, // 承载所有的Coins(即项目)配置
        // 对于该address来说是input【】
        input_stream: Table<address, vector<StreamIndex>>,
        // 对于该address来说是output【】
        output_stream: Table<address, vector<StreamIndex>>,
        stream_events: EventHandle<StreamEvent>, // 事件（便于追溯）
        config_events: EventHandle<ConfigEvent> // 事件（便于追溯）
    }

    // 每一个代币的配置项（也即项目的配置项目，需要更改：VIIP和VDSP的数据结构可能大部分得沉淀到此处）
    struct CoinConfig has store {
        next_id: u64,
        fee_point: u8,
        coin_type: String,
        coin_id: u64,
        escrow_address: address,
        store: Table<u64, StreamInfo>, // 作用是以table结构存储所有的StreamInfo(key是stream自增而来的"全局唯一"编号，StreamInfo是唯一的)
    }

    // 用来标识每一个stream的编号，由coin_id(该平台内部对CoinType的编号)和next_id(该CoinType内部的编号)一起决定
    struct  StreamIndex has store, copy {
        coin_id: u64,
        stream_id: u64
    }

    // [helper]根据CoinType取出对应address
    public fun coin_address<CoinType>(): address {
        let type_info = type_info::type_of<CoinType>();
        type_info::account_address(&type_info)
    }

    // [helper]检查是否满足权限要求(可传入是否一定需要admin身份)
    public fun check_operator(
        operator_address: address,
        require_admin: bool
    ) acquires GlobalConfig {
        assert!(
            // TODO @Stream需要更改
            exists<GlobalConfig>(@Stream), error::already_exists(STREAM_NOT_PUBLISHED),
        );
        assert!(
            !require_admin || admin() == operator_address || @Stream == operator_address, error::permission_denied(STREAM_PERMISSION_DENIED),
        );
    }

    /****************************************************
     * 合约的所有者来设置fee接收者和admin
     * 注: 部署合约的时候就会自动调用(不是，是后面调用来初始化；
     *     如果fee_recipient和admin不更改的话，则应该用init_module在部署时自动初始化)
     ****************************************************/    
    public entry fun initialize(
        owner: &signer, // 该合约中配置的该合约的所有者
        fee_recipient: address,
        admin: address,
    ) {
        let owner_addr = signer::address_of(owner);
        assert!(
            @Stream == owner_addr,
            error::permission_denied(STREAM_PERMISSION_DENIED),
        );

        assert!(
            !exists<GlobalConfig>(@Stream), error::already_exists(STREAM_HAS_PUBLISHED),
        );

        move_to(owner, GlobalConfig {
                fee_recipient,
                admin,
                // 初始化时，项目列表配置为空
                coin_configs: vector::empty<CoinConfig>(),
                input_stream: table::new<address, vector<StreamIndex>>(),
                output_stream: table::new<address, vector<StreamIndex>>(),
                // ???
                stream_events: account::new_event_handle<StreamEvent>(owner), // 创建存储某种事件类型的事件处理器
                config_events: account::new_event_handle<ConfigEvent>(owner)
            }
        );
    }

    /****************************************************
     * 【项目方】注册一个用于流式支付的CoinType，并初始化
     *  疑问: 该CoinType是之前就已经有的还是？（貌似需要之前就发币才行）(其实在该合约内部也可以先创建代币)（该接口是否需要平台方授权同意？不需要！之前确定过）
     *
     *  Memo:
     *  1. 为了支持已有币种或新币种，需要支持CoinType的有无
     *  2. 是不是应该增加接口: register_coin(仅发币), register_project(注册项目)——需要Project Struct
     *  3. 某个生成的资源地址如何查看：GlobalConfig-CoinConfig-escrow_address中
     *
     *
     *  Rethinking:
     *  1. 合约接口名字改为: register_project
     *  2. 调用的接口必须是统一的官方接口: `platform::protocol::register_project`
     *  3. 传入的泛型不应该是CoinType，而应该是ProjectConfig（错了，不应该是泛型，应该是参数；泛型参数必须已存在）
     *  4. 接口逻辑: 根据ProjectConfig生成CoinType，并注册在(账户/资源账户?)下
     *  5. 
     ****************************************************/
    public entry fun register_coin<CoinType>(
        admin: &signer
    ) acquires GlobalConfig {

        /****************************************************
         * 1. 项目方创建 resource account, 并挂载对应代币(数量为0)
         ****************************************************/

        let admin_addr = signer::address_of(admin);
        check_operator(admin_addr, false); // 仅仅核验所依赖的GlobalConfig是否存在(此时，不需要admin，即不需要管理员即可发布CoinType)

        let coin_type = type_info::type_name<CoinType>(); // 获取到CoinType的整个TypeInfo(address,module,struct三者)

        let seed = bcs::to_bytes(&signer::address_of(admin)); // 将16进制的admin地址作为seed，再依次以16进制形式写入@Stream，SALT，coin_type
        vector::append(&mut seed, bcs::to_bytes(&@Stream)); // 写入地址的16进制
        vector::append(&mut seed, SALT); // 写入b"xxx"类型的16进制
        vector::append(&mut seed, *string::bytes(&coin_type)); // 写入struct的16进制

        // escrow address 
        let (resource, _signer_cap) = account::create_resource_account(admin, seed); // 以admin和seed创建resource_account(即escrow address)

        assert!(
            // 判断resource地址下的EScrow<CoinType>类型是否存在(对应：项目方在该资源地址下是否已经部署过该CoinType；当然某个项目方是可以部署多个资源地址的)
            !exists<Escrow<CoinType>>(signer::address_of(&resource)), STREAM_HAS_REGISTERED 
        );

        move_to(
            &resource, 
            Escrow<CoinType> { 
                coin: coin::zero<CoinType>() // 创建value为0的CoinType币种，并挂载在该资源地址上(即项目方的币种是挂载`资源地址`上的)
            }
        );

        /****************************************************
         * 2. 构建对应的CoinConfig，并在全局配置中后缀
         * 注: 在平台的全局配置下(当平台为0x1时，)
         ****************************************************/        

        assert!(
            exists<GlobalConfig>(@Stream), error::already_exists(STREAM_NOT_PUBLISHED), // 为何此处需要判断？
        );
        let global = borrow_global_mut<GlobalConfig>(@Stream);
        let next_coin_id = vector::length(&global.coin_configs);
        
        let _new_coin_config = CoinConfig {
            next_id: 1,
            fee_point: INIT_FEE_POINT, // 默认费率
            coin_type,
            coin_id: next_coin_id, // CoinType内部序列号
            escrow_address: signer::address_of(&resource), // CoinType对应的托管地址(即resource address)
            store: table::new<u64, StreamInfo>(), // TODO
        };

        vector::push_back(&mut global.coin_configs, _new_coin_config)
    }

    /****************************************************
     * 具有CoinType的每个用户都可以构建一个stream(在一定时间范围内，匀速流动转账)
     * 【临时总结】平台方发布该合约并初始化之后，项目方可以发行CoinType，普通用户可以发行定制的Stream
     ****************************************************/      

    /// create a stream
    public entry fun create<CoinType>(
        sender: &signer,
        recipient: address, // sender和recipient是用来定义该stream的源头和目的地的
        deposit_amount: u64, // （总共要流动的value总数）ex: 100,0000
        start_time: u64, // 就是从start_time到stop_time的这段时间，要将deposit_amount的代币平均的流出去
        stop_time: u64,
        coin_id: u64, // 【思考】普通用户在创建时，如何快速获取该coin_id，再用来创建Stream？
    ) acquires GlobalConfig, Escrow {

        /****************************************************
         * 1. 参数的边界校验: 是否有权限执行该操作，存入量，账户是否够该数量
         ****************************************************/

        let sender_address = signer::address_of(sender);
        check_operator(sender_address, false);

        assert!(
            // 【疑问】为什么需要最小存入量的限制？
            deposit_amount >= MIN_DEPOSIT_BALANCE, error::invalid_argument(STREAM_BALANCE_TOO_LITTLE)
        );

        assert!(
            // 【学习】 查询某个地址下某个CoinType的余额
            coin::balance<CoinType>(sender_address) >= deposit_amount, error::invalid_argument(STREAM_INSUFFICIENT_BALANCES)
        );

        /****************************************************
         * 2. 
         * 读取全局配置；
         * 并在校验coin_id之后，取出对应CoinType配置；
         * 再校验对应CoinType；
         * 再根据传入参数确定每秒流动的代币量(不能低于最小精度)；
         ****************************************************/

        assert!(
            exists<GlobalConfig>(@Stream), error::already_exists(STREAM_NOT_PUBLISHED),
        );
        let global = borrow_global_mut<GlobalConfig>(@Stream);

        assert!(
            vector::length(&global.coin_configs) > coin_id, error::not_found(COIN_CONF_NOT_FOUND),
        );
        let _config = vector::borrow_mut(&mut global.coin_configs, coin_id);
        
        assert!(
            _config.coin_type == type_info::type_name<CoinType>(), error::invalid_argument(STREAM_COIN_TYPE_MISMATCH)
        );
        
        let duration = stop_time - start_time;
        let rate_per_second: u64 = deposit_amount * 1000 / duration;

        assert!(
            rate_per_second >= MIN_RATE_PER_SECOND, error::invalid_argument(STREAM_RATE_TOO_LITTLE)
        );

        /****************************************************
         * 2. 构建一个"代币流"结构 (每个代币流都有一个id，该id在对应的CoinType配置中是全局唯一的)
         ****************************************************/    

        let _stream_id = _config.next_id;
        let stream = StreamInfo {
            remaining_balance: 0u64, // 剩余余额为啥初始化时是0？（因为紧接着就会从该账户中withdraw对应deposit_amount量的代币）
            // sender_balance: deposit_amount,
            // recip ient_balance: deposit_amount,
            
            sender: sender_address,
            recipient,
            rate_per_second,
            start_time,
            stop_time,
            last_withdraw_time: start_time,
            deposit_amount,
        };

        // 3. handle assets

        // fee
        // let (fee_num, to_escrow) = calculate_fee(deposit_amount, _config.fee_point); // 2.5 % ---> fee = 250, 2500, 25000, to_escrow = 100,0000 - 2,5000 --> 97,5000
        // let fee_coin = coin::withdraw<CoinType>(sender, fee_num); // 25000
        // coin::deposit<CoinType>(global.fee_recipient, fee_coin); // 21000 or 25000

        /****************************************************
         * 3. 代币(资产)的托管处理: 从sender的账户中withdraw一定数量的代币，并合入该代币唯一指定的"资源地址"中去
         ****************************************************/   

        let to_escrow_coin = coin::withdraw<CoinType>(sender, deposit_amount); // 97,5000 【学习】withdraw一定量的某种类型的币
        stream.remaining_balance = coin::value(&to_escrow_coin); // 【学习】向结构体的某个字段写入一定量的某种类型的币（注：只是写入数字而已）
        merge_coin<CoinType>(_config.escrow_address, to_escrow_coin); // 将withdraw取出的某种类型的代币，合入对应的资源地址(在某种CoinType下，所有用户用来流式分红的的地址都是同一个资源地址)

        /****************************************************
         * 4. 将该某个用户定制的Stream挂载到该CoinType的配置信息中去
         ****************************************************/          

        table::add(&mut _config.store, _stream_id, stream); // 【学习】向某个table中添加某个key-value的方式

        /****************************************************
         * 5. 更新CoinConfig中可用于下一次的对应stream编号
         ****************************************************/          

        _config.next_id = _stream_id + 1;

        /****************************************************
         * 6. 将Stream的"端口"更新到全局配置中去
         *   【注意】output stream to sender, input stream to recipient
         ****************************************************/           

        add_stream_index(&mut global.output_stream, sender_address, StreamIndex{
            coin_id: _config.coin_id,
            stream_id: _stream_id,
        });

        add_stream_index(&mut global.input_stream, recipient, StreamIndex{
            coin_id: _config.coin_id,
            stream_id: _stream_id,
        });

        /****************************************************
         * 7. 将该create过程所对应的Event触发出去，以便追溯
         ****************************************************/    

        event::emit_event<StreamEvent>( // 【学习】: 主动触发某种Event的写法
            &mut global.stream_events,
            StreamEvent {
                id: _stream_id,
                coin_id: _config.coin_id,
                event_type: EVENT_TYPE_CREATE,
                remaining_balance: deposit_amount
            },
        );
    }

    // 【疑问】：为什么要将该Stream挂载到全局?
    // TODO：此处的数据结构和操作方式貌似可以优化(因为内置的table等数据结构提供了类似功能)！
    fun add_stream_index(stream_table: &mut Table<address, vector<StreamIndex>>, key_address: address, stream_index: StreamIndex ) {
        if (!table::contains(stream_table, key_address)){ // 【学习】: 判断table中是否有某个key，没有的话先创建再写入
            table::add(
                stream_table,
                key_address,
                vector::empty<StreamIndex>(),
            )
        };

        let sender_stream = table::borrow_mut(stream_table, key_address);

        vector::push_back(sender_stream, stream_index);
    }

    // 延长Stream的结束时间
    // TODO 调整顺序 辅助函数和接口函数分开
    public entry fun extend<CoinType>(
        sender: &signer,
        new_stop_time: u64,
        coin_id: u64,
        stream_id: u64,
    ) acquires GlobalConfig, Escrow {
        // 1. check args

        let sender_address = signer::address_of(sender);
        check_operator(sender_address, false);

        // 2. get _config
        assert!(
            exists<GlobalConfig>(@Stream), error::already_exists(STREAM_NOT_PUBLISHED),
        );
        let global = borrow_global_mut<GlobalConfig>(@Stream);

        assert!(
            vector::length(&global.coin_configs) > coin_id, error::not_found(COIN_CONF_NOT_FOUND),
        );
        let _config = vector::borrow_mut(&mut global.coin_configs, coin_id);

        assert!(
            _config.coin_type == type_info::type_name<CoinType>(), error::invalid_argument(STREAM_COIN_TYPE_MISMATCH)
        );

        // 3. check stream stats
        assert!(
            table::contains(&_config.store, stream_id), error::not_found(STREAM_NOT_FOUND),
        );
        let stream = table::borrow_mut(&mut _config.store, stream_id);
        assert!(stream.sender == sender_address, error::invalid_argument(STREAM_PERMISSION_DENIED));

        /****************************************************
         * 重新计算
         ****************************************************/         

        assert!(new_stop_time > stream.stop_time, ERR_NEW_STOP_TIME);
        let deposit_amount = (new_stop_time - stream.stop_time) * stream.rate_per_second / 1000;
        assert!(
            coin::balance<CoinType>(sender_address) >= deposit_amount, error::invalid_argument(STREAM_INSUFFICIENT_BALANCES)
        );

        // 4. handle assets

        // to escrow
        let to_escrow_coin = coin::withdraw<CoinType>(sender, deposit_amount); // 97,5000
        merge_coin<CoinType>(_config.escrow_address, to_escrow_coin);

        // 5. update stream stats

        stream.stop_time = new_stop_time;
        stream.remaining_balance = stream.remaining_balance + deposit_amount;
        stream.deposit_amount = stream.deposit_amount + deposit_amount;

        // 6. emit open event

        event::emit_event<StreamEvent>(
            &mut global.stream_events,
            StreamEvent {
                id: stream_id,
                coin_id: _config.coin_id,
                event_type: EVENT_TYPE_EXTEND,
                remaining_balance: stream.remaining_balance
            },
        );
    }

    public entry fun close<CoinType>(
        sender: &signer,
        coin_id: u64,
        stream_id: u64,
    ) acquires GlobalConfig, Escrow {
        // 1. check args

        let sender_address = signer::address_of(sender);
        check_operator(sender_address, false);

        // 2. withdraw

        withdraw<CoinType>(sender, coin_id, stream_id);

        // 3. get _config

        let global = borrow_global_mut<GlobalConfig>(@Stream);
        let _config = vector::borrow_mut(&mut global.coin_configs, coin_id);
        assert!(
            _config.coin_type == type_info::type_name<CoinType>(), error::invalid_argument(STREAM_COIN_TYPE_MISMATCH)
        );

        // 4. check stream stats

        let stream = table::borrow_mut(&mut _config.store, stream_id);
        assert!(stream.sender == sender_address, error::invalid_argument(STREAM_PERMISSION_DENIED));

        let escrow_coin = borrow_global_mut<Escrow<CoinType>>(_config.escrow_address);

        assert!(
            stream.remaining_balance <= coin::value(&escrow_coin.coin),
            error::invalid_argument(STREAM_INSUFFICIENT_BALANCES),
        );

        // 5. handle assets

        coin::deposit(sender_address, coin::extract(&mut escrow_coin.coin, stream.remaining_balance));

        // 6. update stream stats

        stream.remaining_balance = 0;

        // 7. emit open event

        event::emit_event<StreamEvent>(
            &mut global.stream_events,
            StreamEvent {
                id: stream_id,
                coin_id: _config.coin_id,
                event_type: EVENT_TYPE_CLOSE,
                remaining_balance: 0
            },
        );
    }

    /****************************************************
     * 将一定量的CoinType类型的Coin合并到resource地址上
     ****************************************************/

    fun merge_coin<CoinType>(
        resource: address,
        coin: Coin<CoinType>
    ) acquires Escrow {
        let escrow = borrow_global_mut<Escrow<CoinType>>(resource);
        coin::merge(&mut escrow.coin, coin);
    }


    /****************************************************
     * 用户从公共托管的资源账户withdraw一些对应代币(比例为流逝的时间占比)
     * 思考: 任意地址都可以发起该withdraw吗？ （理论上是可以的，因为每个stream中固定了recepient!）
     ****************************************************/

    public entry fun withdraw<CoinType>(
        operator: &signer,
        coin_id: u64,
        stream_id: u64,
    ) acquires GlobalConfig, Escrow {
        // 1. check args
        let operator_address = signer::address_of(operator);
        check_operator(operator_address, false);

        // 2. get handler
        assert!(
            exists<GlobalConfig>(@Stream), error::already_exists(STREAM_NOT_PUBLISHED),
        );
        let global = borrow_global_mut<GlobalConfig>(@Stream);

        assert!(
            vector::length(&global.coin_configs) > coin_id, error::not_found(COIN_CONF_NOT_FOUND),
        );
        let _config = vector::borrow_mut(&mut global.coin_configs, coin_id);

        assert!(
            _config.coin_type == type_info::type_name<CoinType>(), error::invalid_argument(STREAM_COIN_TYPE_MISMATCH)
        );

        // 3. check stream stats
        assert!(
            table::contains(&_config.store, stream_id), error::not_found(STREAM_NOT_FOUND),
        );
        let stream = table::borrow_mut(&mut _config.store, stream_id);
        let escrow_coin = borrow_global_mut<Escrow<CoinType>>(_config.escrow_address);
        
        /****************************************************
         * 计算上一次withdraw时间到此刻时间的时间戳数量(因为全局存储了每秒需要支付的代币，因此只要求出秒数即可)，并更新时间戳
         ****************************************************/

        let (delta, last_withdraw_time) = delta_of(stream.last_withdraw_time, stream.stop_time);
        let withdraw_amount = stream.rate_per_second * delta / 1000;

        assert!(
            withdraw_amount <= stream.remaining_balance && withdraw_amount <= coin::value(&escrow_coin.coin),
            error::invalid_argument(STREAM_INSUFFICIENT_BALANCES),
        );

        /****************************************************
         * 处理代币资产
         * 1.计算出扣除的手续费和实际到手的代币数量
         * 2.从资源账户中extract出一定数量的手续费代币，再deposit到全局唯一配置的fee_recipient(手续费接收者)
         * 3.将剩余数量的代币deposit给该stream的recipient接收者
         ****************************************************/        
        let (fee_num, to_recipient) = calculate_fee(withdraw_amount, _config.fee_point); // 2.5 % ---> fee = 250, 2500, 25000, to_escrow = 100,0000 - 2,5000 --> 97,5000
        coin::deposit<CoinType>(global.fee_recipient, coin::extract(&mut escrow_coin.coin, fee_num)); // 【学习】extract和deposit的使用
        coin::deposit<CoinType>(stream.recipient, coin::extract(&mut escrow_coin.coin, to_recipient));

         
        /****************************************************
         * 更新该stream的剩余代币数量(即在对应资源账户上，自己所拥有的那一部分)
         ****************************************************/

        stream.remaining_balance = stream.remaining_balance - withdraw_amount;
        stream.last_withdraw_time = last_withdraw_time;

                
        /****************************************************
         * 触发Withdraw事件，以便回溯
         ****************************************************/

        event::emit_event<StreamEvent>(
            &mut global.stream_events,
            StreamEvent {
                id: stream_id,
                coin_id: _config.coin_id,
                event_type: EVENT_TYPE_WITHDRAW,
                remaining_balance: stream.remaining_balance
            },
        );
    }

    /****************************************************
     * 设置配置中的新的手续费(只有该合约的拥有者才可以)
     ****************************************************/
    public entry fun set_fee_point(
        owner: &signer,
        coin_id: u64,
        new_fee_point: u8,
    ) acquires GlobalConfig {
        let operator_address = signer::address_of(owner);
        assert!(
            @Stream == operator_address, error::invalid_argument(STREAM_PERMISSION_DENIED),
        );

        assert!(
            exists<GlobalConfig>(@Stream), error::already_exists(STREAM_NOT_PUBLISHED),
        );
        let global = borrow_global_mut<GlobalConfig>(@Stream);

        assert!(
            vector::length(&global.coin_configs) > coin_id, error::not_found(COIN_CONF_NOT_FOUND),
        );
        let _config = vector::borrow_mut(&mut global.coin_configs, coin_id);

        _config.fee_point = new_fee_point;

        event::emit_event<ConfigEvent>(
            &mut global.config_events,
            ConfigEvent {
                coin_id: _config.coin_id,
                fee_point: _config.fee_point
            },
        );
    }

    /****************************************************
     * 计算手续费
     * 根据CoinConfig中的fee_point和计算出来的需要withdraw的代币数量。
     * 来计算手续费和真实到手的代币数量
     ****************************************************/
    public fun calculate_fee(
        withdraw_amount: u64,
        fee_point: u8,
    ): (u64, u64) {
        let fee = withdraw_amount * (fee_point as u64) / 10000;

        // never overflow
        (fee, withdraw_amount - fee)
    }

    /****************************************************
     * 计算新的待支付时间长度和新的支付时间
     ****************************************************/    
    public fun delta_of(last_withdraw_time: u64, stop_time: u64) : (u64, u64) {
        let current_time = timestamp::now_seconds();
        let delta = stop_time - last_withdraw_time;

        if(current_time < last_withdraw_time){
            return (0u64, current_time)
        };

        if(current_time < stop_time){
            return (current_time - last_withdraw_time, current_time)
        };

        (delta, stop_time)
    }

    // public views for global config start

    /****************************************************
     * 从全局配置信息中取出admin地址
     ****************************************************/      
    public fun admin(): address acquires GlobalConfig {
        assert!(
            exists<GlobalConfig>(@Stream), error::already_exists(STREAM_NOT_PUBLISHED),
        );
        borrow_global<GlobalConfig>(@Stream).admin
    }

    /****************************************************
     * 从全局配置中取出某个CoinType的手续费
     ****************************************************/        
    public fun fee_point(coin_id: u64): u8 acquires GlobalConfig {
        assert!(
            exists<GlobalConfig>(@Stream), error::already_exists(STREAM_NOT_PUBLISHED),
        );
        let global = borrow_global<GlobalConfig>(@Stream);

        assert!(
            vector::length(&global.coin_configs) > coin_id, error::not_found(COIN_CONF_NOT_FOUND),
        );
        // 从vector中取出某个coin_id对应的配置(vector是可以根据index取出对应值的)
        vector::borrow(&global.coin_configs, coin_id).fee_point
    }

    /****************************************************
     * 从全局配置中取出某个CoinType的手续费
     ****************************************************/  
    public fun next_id(coin_id: u64): u64 acquires GlobalConfig {
        assert!(
            exists<GlobalConfig>(@Stream), error::already_exists(STREAM_NOT_PUBLISHED),
        );
        let global = borrow_global<GlobalConfig>(@Stream);

        assert!(
            vector::length(&global.coin_configs) > coin_id, error::not_found(COIN_CONF_NOT_FOUND),
        );
        vector::borrow(&global.coin_configs, coin_id).next_id
    }

    /****************************************************
     * 从全局配置中取出某个CoinType的coin_type(address,module,struct三者信息的结构体)
     ****************************************************/  
    public fun coin_type(coin_id: u64): String acquires GlobalConfig {
        assert!(
            exists<GlobalConfig>(@Stream), error::already_exists(STREAM_NOT_PUBLISHED),
        );
        let global = borrow_global<GlobalConfig>(@Stream);

        assert!(
            vector::length(&global.coin_configs) > coin_id, error::not_found(COIN_CONF_NOT_FOUND),
        );
        vector::borrow(&global.coin_configs, coin_id).coin_type
    }

    /****************************************************
     * Testing
     ****************************************************/      

    #[test_only]
    struct FakeCoin {}

    #[test(account = @0x1, stream= @Stream, admin = @Admin)] // test时的临时变量
    fun test(account: signer, stream: signer, admin: signer) acquires GlobalConfig, Escrow {

        /****************************************************
         * 1. 挂载一个定时器给account（目前只有account才有权限）
         *    注：set_time_has_started_for_testing是一个test_only函数
         ****************************************************/  

        timestamp::set_time_has_started_for_testing(&account);

        /****************************************************
         * 2. 创建address创建用于test的account和admin
         *    注：
         *    1. account::create_account_for_test是创建虚拟账号?
         *    2. debug::print是背后调用的是native方法(那么如何打印别的类型呢？见eschain::protocol的实现)
         ****************************************************/  
        let stream_addr = signer::address_of(&stream);
        account::create_account_for_test(stream_addr);
        debug::print(&stream_addr);

        let admin_addr = signer::address_of(&admin);
        account::create_account_for_test(admin_addr);
        debug::print(&admin_addr);

        let account_addr = signer::address_of(&account);
        account::create_account_for_test(account_addr);
        debug::print(&account_addr);

        /****************************************************
         * 3. 创建address创建用于test的account和admin地址，并给admin铸造一定量的某种代币
         *    1. managed_coin::initialize在该合约地址下挂载代币能力
         *    2. 在account,admin,stream三个地址下注册该代币，以便deposit
         *
         *    3. 由该合约给admin_addr铸造100000
         ****************************************************/          

        let name = b"Fake Coin";
        let symbol = b"FCC";

        managed_coin::initialize<FakeCoin>(&stream, name, symbol, 8, false);
        managed_coin::register<FakeCoin>(&account);
        managed_coin::register<FakeCoin>(&admin);
        managed_coin::register<FakeCoin>(&stream);
        managed_coin::mint<FakeCoin>(&stream, admin_addr, 100000);
        assert!(coin::balance<FakeCoin>(admin_addr) == 100000, 0); // 【学习】读取地址余额

        /****************************************************
         * 4. 调用待测试的合约接口：调用initialize来配置fee接收者和admin地址
         ****************************************************/          
        assert!(!exists<GlobalConfig>(@Stream), 1);
        let recipient = stream_addr;
        initialize(&stream, recipient, admin_addr);
        assert!(exists<GlobalConfig>(@Stream), 2);

        /****************************************************
         * 5. 调用待测试的合约接口：项目方注册FakeCoin代币(并前置&后置校验，以及对应CoinConfig中字段校验)
         ****************************************************/       
        register_coin<FakeCoin>(&admin);
        assert!(!exists<Escrow<FakeCoin>>(admin_addr), 3); // ?
        assert!(coin_type(0) == type_info::type_name<FakeCoin>(), 4);
        assert!(next_id(0) == 1, 5);
        assert!(fee_point(0) == INIT_FEE_POINT, 5);

        
        /****************************************************
         * 6. 调用待测试的合约接口：用户在对应CoinType中创建一个"流式支付"
         *   1. 并校验创建流式支付后其账户余额——因为创建时就要deposit一定量的代币到公共账户
         *   2. 校验对应CoinConfig相应字段
         *   3. 取出对应的(刚创建的)stream
         *   4. 校验流式支付recipient一开始的余额
         *   5. 校验公共托管地址escrow_address在deposit之后的初始余额
         *   6. 批量校验创建的stream的各个字段是否符合预期
         ****************************************************/          
        create<FakeCoin>(&admin, recipient, 60000, 10000, 10005, 0);
        assert!(coin::balance<FakeCoin>(admin_addr) == 40000, 0);

        let global = borrow_global_mut<GlobalConfig>(@Stream);
        let _config = vector::borrow(&global.coin_configs, 0);

        assert!(_config.next_id == 2, 5);
        let _stream = table::borrow(&_config.store, 1); // 【学习】从table中取出key对应的value
        debug::print(&coin::balance<FakeCoin>(recipient)); // 【学习】查询某个"普通"地址在某个CoinType下的余额
        let escrow_coin = borrow_global<Escrow<FakeCoin>>(_config.escrow_address);
        debug::print(&coin::value(&escrow_coin.coin)); // 【学习】查询某个"资源"地址在某个CoinType下的余额
        assert!(_stream.recipient == recipient, 0);
        assert!(_stream.sender == admin_addr, 0);
        assert!(_stream.start_time == 10000, 0);
        assert!(_stream.stop_time == 10005, 0);
        assert!(_stream.deposit_amount == 60000, 0);
        assert!(_stream.remaining_balance == coin::value(&escrow_coin.coin), 0);
        assert!(_stream.rate_per_second == 60000 * 1000/5, 0);
        assert!(_stream.last_withdraw_time == 10000, 0);

        /****************************************************
         * 7. 调用待测试的合约接口：调用withdraw
         *    1. 先查询recipient余额
         *    2. 更新用于"测试"的全局时间戳
         *    3. 针对该stream发起withdraw(发起方谁都可)
         *    4. 取出该CoinConfig中的stream，并验证
         ****************************************************/                
        let beforeWithdraw = coin::balance<FakeCoin>(recipient);
        debug::print(&coin::balance<FakeCoin>(recipient));

        timestamp::update_global_time_for_test_secs(10000); // 【学习】更新全局时间戳
        withdraw<FakeCoin>(&stream, 0, 1);
        debug::print(&coin::balance<FakeCoin>(recipient));
        let global = borrow_global_mut<GlobalConfig>(@Stream);
        let _config = vector::borrow(&global.coin_configs, 0);
        let _stream = table::borrow(&_config.store, 1);
        assert!(_stream.last_withdraw_time == 10000, 0);
        assert!(coin::balance<FakeCoin>(recipient) == beforeWithdraw, 0);

        /****************************************************
         * 8. 调用待测试的合约接口[连续测试6次]：每隔1秒调用一次withdraw
         *    1. 时间快进1秒
         *    2. 调用1次withdraw
         *    3. 打印recipient余额
         *    4. 取出全局配置
         *    5. 取出CoinConfig
         *    5. 取出其中的Stream
         *    6. 校验该Stream的"上次取款时间"
         *    7. 校验该recipient的当前余额确实等于之前余额加上withdraw的数量
         ****************************************************/          

        timestamp::fast_forward_seconds(1); // 【学习】用于测试目的的"时间快进"
        withdraw<FakeCoin>(&stream, 0, 1);
        debug::print(&coin::balance<FakeCoin>(recipient));

        let global = borrow_global_mut<GlobalConfig>(@Stream);
        let _config = vector::borrow(&global.coin_configs, 0);
        let _stream = table::borrow(&_config.store, 1);

        assert!(_stream.last_withdraw_time == 10001, 0);
        assert!(coin::balance<FakeCoin>(recipient) == beforeWithdraw + 60000/5 * 1, 0);

        timestamp::fast_forward_seconds(1);
        withdraw<FakeCoin>(&stream, 0, 1);
        debug::print(&coin::balance<FakeCoin>(recipient));
        let global = borrow_global_mut<GlobalConfig>(@Stream);
        let _config = vector::borrow(&global.coin_configs, 0);
        let _stream = table::borrow(&_config.store, 1);
        assert!(_stream.last_withdraw_time == 10002, 0);
        assert!(coin::balance<FakeCoin>(recipient) == beforeWithdraw + 60000/5 * 2, 0);

        timestamp::fast_forward_seconds(1);
        withdraw<FakeCoin>(&stream, 0, 1);
        debug::print(&coin::balance<FakeCoin>(recipient));
        let global = borrow_global_mut<GlobalConfig>(@Stream);
        let _config = vector::borrow(&global.coin_configs, 0);
        let _stream = table::borrow(&_config.store, 1);
        assert!(_stream.last_withdraw_time == 10003, 0);
        assert!(coin::balance<FakeCoin>(recipient) == beforeWithdraw + 60000/5 * 3, 0);

        timestamp::fast_forward_seconds(1);
        withdraw<FakeCoin>(&stream, 0, 1);
        debug::print(&coin::balance<FakeCoin>(recipient));
        let global = borrow_global_mut<GlobalConfig>(@Stream);
        let _config = vector::borrow(&global.coin_configs, 0);
        let _stream = table::borrow(&_config.store, 1);
        assert!(_stream.last_withdraw_time == 10004, 0);
        assert!(coin::balance<FakeCoin>(recipient) == beforeWithdraw + 60000/5 * 4, 0);

        timestamp::fast_forward_seconds(1);
        withdraw<FakeCoin>(&stream, 0, 1);
        debug::print(&coin::balance<FakeCoin>(recipient));
        let global = borrow_global_mut<GlobalConfig>(@Stream);
        let _config = vector::borrow(&global.coin_configs, 0);
        let _stream = table::borrow(&_config.store, 1);
        assert!(_stream.last_withdraw_time == 10005, 0);
        assert!(coin::balance<FakeCoin>(recipient) == beforeWithdraw + 60000/5 * 5, 0);

        timestamp::fast_forward_seconds(1);
        withdraw<FakeCoin>(&stream, 0, 1);
        debug::print(&coin::balance<FakeCoin>(recipient));
        let global = borrow_global_mut<GlobalConfig>(@Stream);
        let _config = vector::borrow(&global.coin_configs, 0);
        let _stream = table::borrow(&_config.store, 1);
        assert!(_stream.last_withdraw_time == _stream.stop_time, 0);
        assert!(coin::balance<FakeCoin>(recipient) == beforeWithdraw + 60000/5 * 5, 0);
    }
}


/****************************************************
【创建账户并发布到链上】
./aptos init --profile recipient
./aptos account create --account recipient
---------------------------------------------------
【测试】
./aptos move test

【编译】
./aptos move compile

【发布】
./aptos move publish --profile=platformer
---------------------------------------------------
【合约调用-设置fee_recipient和admin】
./aptos move run --function-id default::protocol::initialize --args address:recipient address:admin

> 注: 此时的Profiles中, default就是代码中定义的Platform(平台方)
> 

【合约调用-注册Project】
ts调用

> 注: 0xcf075d17aa95ff1abba520ddc57c98c94ed4d780b64a3f62f005f8976d9862da对应的资源地址(在GlobalConfig-CoinConfig-escrow_address)：0x1933f90ddf2403c31a5646eb95f8df6636ea32c486f17d6a4782712a3b12d1e4






备注: EntryFunctionPayload的参数: {function: string, type_arguments: [MoveType], arguments: [any]}
/**
 * MoveType如下:
 * 
 * String representation of an on-chain Move type tag that is exposed in transaction payload.
 * Values:
 * - bool
 * - u8
 * - u16
 * - u32
 * - u64
 * - u128
 * - u256
 * - address
 * - signer
 * - vector: `vector<{non-reference MoveTypeId}>`
 * - struct: `{address}::{module_name}::{struct_name}::<{generic types}>`
 *
 * Vector type value examples:
 * - `vector<u8>`
 * - `vector<vector<u64>>`
 * - `vector<0x1::coin::CoinStore<0x1::aptos_coin::AptosCoin>>`
 *
 * Struct type value examples:
 * - `0x1::coin::CoinStore<0x1::aptos_coin::AptosCoin>
 * - `0x1::account::Account`
 *
 * Note:
 * 1. Empty chars should be ignored when comparing 2 struct tag ids.
 * 2. When used in an URL path, should be encoded by url-encoding (AKA percent-encoding).
 *
 */





---
profiles:
  default:
    private_key: "0xb447e43e6ae689e83984ef3002262e4a873daa429ba26455d8f0f3aea8d769f2"
    public_key: "0x7d383ce992c545c74913adc0fd403239e033274ae298dcc5cb525a3b04965038"
    account: fae0c31c093cf9d1077c8e07361daa36ce71f6eb0737491b7c03657bdeadbab7
    rest_url: "http://localhost:8080"
    faucet_url: "http://localhost:8000"
  admin:
    private_key: "0x074831d3314be25f9706458ef69bf6585212665eef8b4bcd62cc362ad4bb2b84"
    public_key: "0xa8ce3fe73643c323f54cd402c7afd4dccc9b6b4abc724a020cdf83b3af286a52"
    account: e680bde5f381ec99fb651c410f8ed40bb2dd803b1f4afd2c15d5d35131a33dd6
    rest_url: "http://localhost:8080"
    faucet_url: "http://localhost:8000"
  recipient:
    private_key: "0x9ce2b03835b8955e85ee72b3f130b8966730755eceeb2e37d70d057d73fdc3d0"
    public_key: "0x0a26d594ebb03540f4e110da37a8e308c9c10ae815c75001f2f4e4aef9142fd0"
    account: 677976c6bc0c9f7904fed53a09c588ae6669dc700017c8d0b8d457acba481069
    rest_url: "http://localhost:8080"
    faucet_url: "http://localhost:8000"













****************************************************/