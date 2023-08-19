import { Stave } from './stave';
import { StaveModifier } from './stavemodifier';
export declare class StaveSection extends StaveModifier {
    static get CATEGORY(): string;
    protected section: string;
    protected shiftX: number;
    protected shiftY: number;
    protected drawRect: boolean;
    constructor(section: string, x: number, shiftY: number, drawRect?: boolean);
    setStaveSection(section: string): this;
    setShiftX(x: number): this;
    setShiftY(y: number): this;
    draw(stave: Stave, shiftX: number): this;
}
