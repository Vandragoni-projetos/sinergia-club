<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login - Acesso à Plataforma</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
    <script src="https://unpkg.com/lucide@latest"></script>
    <style id="theme-vars">
        :root {
            --brand-primary: #32e768;
            --brand-primary-hover: #28d15e;
            --theme-bg: #07090d;
            --accent-primary: #32e768;
            --accent-primary-hover: #28d15e;
        }
        .bg-dark-base { background-color: var(--theme-bg, #07090d); }
    </style>
    <style>
        body { font-family: 'Plus Jakarta Sans', sans-serif; }
        .modern-input-group { position: relative; transition: all 0.3s ease; }
        .modern-input {
            width: 100%;
            padding: 1rem 1rem 1rem 3rem;
            background-color: #0f1419;
            border: 1px solid rgba(255, 255, 255, 0.1);
            border-radius: 1rem;
            color: white;
            font-size: 0.95rem;
            transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
        }
        .modern-input:focus {
            outline: none;
            background-color: #1a1f24;
            border-color: var(--accent-primary);
            box-shadow: 0 4px 20px -2px rgba(50, 231, 104, 0.15);
            transform: translateY(-1px);
        }
        .input-icon {
            position: absolute;
            left: 1rem;
            top: 50%;
            transform: translateY(-50%);
            color: #94a3b8;
        }
        .btn-primary { background: var(--accent-primary); position: relative; overflow: hidden; z-index: 1; }
        @keyframes float-up {
            0% { opacity: 0; transform: translateY(40px) scale(0.9); }
            10% { opacity: 1; transform: translateY(0) scale(1); }
            90% { opacity: 1; transform: translateY(0) scale(1); }
            100% { opacity: 0; transform: translateY(-40px) scale(0.9); }
        }
        .notification-card { animation: float-up 4s ease-in-out forwards; }
        .glass-effect {
            background: rgba(15, 20, 25, 0.7);
            backdrop-filter: blur(20px) saturate(180%);
            -webkit-backdrop-filter: blur(20px) saturate(180%);
            border: 1px solid rgba(255, 255, 255, 0.15);
        }
    </style>
</head>
<body class="min-h-screen" style="background-color: var(--theme-bg, #07090d);">
    <div class="min-h-screen grid lg:grid-cols-2">
        <div class="hidden lg:flex relative flex-col justify-end p-12 overflow-hidden bg-slate-900" style="background-image: url('https://img.freepik.com/fotos-premium/cabelo-encaracolado-de-jovem-feliz-sorrindo-e-rindo-ela-esta-feliz-em-estudio-isolado-com-solido-brilhante_39704-6416.jpg'); background-size: cover; background-position: center;">
            <div class="absolute inset-0 bg-gradient-to-t from-black via-black/40 to-transparent"></div>
            <div id="notifications-wrapper" class="absolute inset-0 pointer-events-none z-20 p-8 flex flex-col justify-start items-start gap-4" style="padding-top: 8rem;"></div>
            <div class="relative z-20 mb-8 max-w-lg">
                <h1 class="text-5xl font-bold text-white mb-4 leading-tight">
                    Transforme ideias em vendas. <br>
                    <span class="text-transparent bg-clip-text" style="background-image: linear-gradient(to right, var(--accent-primary), rgba(50, 231, 104, 0.6));">Venda mais. Cresça todos os dias.</span>
                </h1>
                <p class="text-gray-300 text-lg leading-relaxed">
                    Produtos digitais, ferramentas e soluções para quem quer transformar conhecimento em resultado.
                </p>
            </div>
        </div>
        <div class="flex items-center justify-center p-8 bg-dark-base">
            <div class="w-full max-w-[420px] space-y-8">
                <div class="text-center">
                    <div class="inline-flex justify-center mb-6 p-4 rounded-3xl mb-6">
                        <img src="https://midias.vitrineacademy.com.br/wp-content/uploads/2026/03/Logomarca-Hub-Sinergia-1000x412-1.png" alt="Logo" class="w-auto h-16 object-contain">
                    </div>
                    <h2 class="text-3xl font-bold text-white tracking-tight">Bem-vindo de volta!</h2>
                    <p class="text-gray-400 mt-2">Acesse sua conta para gerenciar seu império.</p>
                </div>
                <div class="bg-blue-50 border border-blue-200 text-blue-800 px-4 py-4 rounded-xl flex items-start gap-3 shadow-sm">
                    <i data-lucide="info" class="w-5 h-5 flex-shrink-0 text-blue-600 mt-0.5"></i>
                    <div class="text-sm">
                        <p class="font-semibold mb-1">Primeira vez aqui?</p>
                        <p class="leading-relaxed">Sua senha de acesso foi enviada para o <strong>e-mail de compra</strong>. Não esqueça de verificar a <strong>caixa de spam</strong> caso não encontre a mensagem.</p>
                    </div>
                </div>
                <form class="space-y-6" onsubmit="return false;">
                    <div class="space-y-5">
                        <div class="modern-input-group">
                            <label for="usuario" class="block text-gray-300 text-sm font-bold mb-2 ml-1">Usuário</label>
                            <div class="relative">
                                <i data-lucide="user" class="input-icon w-5 h-5"></i>
                                <input type="text" name="usuario" id="usuario" class="modern-input" placeholder="exemplo@email.com">
                            </div>
                        </div>
                        <div class="modern-input-group">
                            <label for="senha" class="block text-gray-300 text-sm font-bold mb-2 ml-1">Senha</label>
                            <div class="relative">
                                <i data-lucide="lock" class="input-icon w-5 h-5"></i>
                                <input type="password" name="senha" id="senha" class="modern-input pr-12" placeholder="••••••••">
                            </div>
                        </div>
                        <div class="flex items-center justify-between">
                            <span class="text-sm font-medium text-gray-400">Lembrar meu acesso</span>
                            <span class="text-sm font-medium" style="color: var(--accent-primary);">Esqueci minha senha</span>
                        </div>
                    </div>
                    <div class="border-2 rounded-xl p-4" style="border-color: rgba(255, 255, 255, 0.1); background-color: rgba(15, 20, 25, 0.5);">
                        <span class="text-sm font-medium text-gray-300">Não sou um robô</span>
                    </div>
                    <button type="submit" class="btn-primary w-full text-white font-bold py-4 px-6 rounded-xl">Acessar Painel</button>
                </form>
                <div class="mt-6">
                    <div class="relative flex justify-center text-sm">
                        <span class="px-4 text-gray-400" style="background-color: var(--theme-bg, #07090d);">Ainda não tem uma conta?</span>
                    </div>
                    <a href="#" class="mt-4 w-full border-2 border-gray-700 text-white font-bold py-3 px-6 rounded-xl flex items-center justify-center gap-2">Criar Conta Grátis</a>
                </div>
            </div>
        </div>
    </div>
    <script>
        lucide.createIcons();
        const wrapper = document.getElementById('notifications-wrapper');
        const names = ['Fernanda L.', 'Gabriel S.', 'Beatriz C.', 'Lucas R.', 'Mariana P.', 'Carlos M.', 'Juliana A.', 'Rafael T.'];
        const notificationImageUrl = 'https://midias.vitrineacademy.com.br/wp-content/uploads/2026/03/Logomarca-Hub-Sinergia-1000x412-1.png';
        const ticketValues = [19.90, 27.90, 29.90, 37.90, 47.90, 59.90, 67.90];
        const actions = [
            { type: 'Venda Aprovada', icon: 'check-circle', color: 'text-green-500' },
            { type: 'Venda Cartão', icon: 'credit-card', color: 'text-orange-500' },
            { type: 'PIX Gerado', icon: 'qr-code', color: 'text-blue-500' },
            { type: 'PIX Aprovado', icon: 'check-circle', color: 'text-green-500' }
        ];
        function formatCurrency(value) {
            return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(value);
        }
        function createNotification() {
            if (!wrapper) return;
            if (wrapper.children.length > 3) wrapper.removeChild(wrapper.firstChild);
            const randomName = names[Math.floor(Math.random() * names.length)];
            const randomAction = actions[Math.floor(Math.random() * actions.length)];
            const randomValue = ticketValues[Math.floor(Math.random() * ticketValues.length)];
            const notif = document.createElement('div');
            notif.className = 'notification-card glass-effect rounded-2xl p-4 flex items-center gap-4 w-72 transform transition-all shadow-xl';
            notif.style.borderLeft = '4px solid var(--accent-primary)';
            notif.innerHTML = `
                <div class="p-2 rounded-full flex-shrink-0" style="background: linear-gradient(135deg, rgba(50, 231, 104, 0.2), rgba(50, 231, 104, 0.1)); border: 1px solid rgba(50, 231, 104, 0.3);">
                    <img src="${notificationImageUrl}" alt="Logo" class="w-8 h-8 object-contain">
                </div>
                <div class="flex-1 min-w-0">
                    <div class="flex justify-between items-start mb-1">
                        <p class="text-xs font-bold text-white truncate" style="color: var(--accent-primary);">${randomAction.type}</p>
                        <span class="text-[10px] text-gray-400 flex-shrink-0 ml-2">Agora</span>
                    </div>
                    <p class="text-sm font-extrabold text-white mt-0.5">${formatCurrency(randomValue)}</p>
                    <p class="text-[10px] text-gray-400 truncate">${randomName} acabou de comprar</p>
                </div>
            `;
            wrapper.appendChild(notif);
            setTimeout(() => {
                if(notif.parentNode === wrapper) wrapper.removeChild(notif);
            }, 4000);
        }
        function startNotificationLoop() {
            createNotification();
            const nextTime = Math.random() * 2000 + 1500;
            setTimeout(startNotificationLoop, nextTime);
        }
        if (window.innerWidth >= 1024) {
            setTimeout(startNotificationLoop, 1000);
        }
    </script>
</body>
</html>
