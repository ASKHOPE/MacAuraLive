class SnowEffect {
    constructor(parameters = {}) {
        this.type = 'snow';
        this.baseParameters = { ...parameters };
        this.parameters = { ...parameters };
        this.flakes = [];
        this.init();
    }

    init() {
        const count = parseInt(this.parameters.density || 200);
        this.flakes = [];
        for (let i = 0; i < count; i++) {
            this.flakes.push({
                x: Math.random() * 1920,
                y: Math.random() * 1080,
                radius: Math.random() * 3 + 1,
                speed: Math.random() * 2 + 1,
                swing: Math.random() * 0.05
            });
        }
    }

    resize(w, h) {
        this.width = w;
        this.height = h;
    }

    update(dt) {
        const speedMult = parseFloat(this.parameters.speed || 1.0);
        for (let f of this.flakes) {
            f.y += f.speed * speedMult;
            f.x += Math.sin(f.y * 0.02) * 0.8;

            if (f.y > (this.height || 1080)) {
                f.y = -f.radius;
                f.x = Math.random() * (this.width || 1920);
            }
        }
    }

    render(ctx, w, h) {
        ctx.fillStyle = this.parameters.color || '#ffffff';
        ctx.globalAlpha = parseFloat(this.parameters.opacity || 0.8);

        for (let f of this.flakes) {
            ctx.beginPath();
            ctx.arc(f.x, f.y, f.radius, 0, Math.PI * 2);
            ctx.fill();
        }
        ctx.globalAlpha = 1.0;
    }
}

EffectRegistry.register('snow', SnowEffect);
