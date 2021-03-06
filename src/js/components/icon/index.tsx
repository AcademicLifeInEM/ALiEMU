import { memo } from '@wordpress/element';
import classNames from 'classnames';

interface SharedProps {
    /**
     * Size of icon in px.
     *
     * @default 18
     */
    size?: number;

    /**
     * An optional class name for the icon
     */
    className?: string;

    /**
     * This component doesn't support children
     */
    children?: never;
}

export interface IconProps extends SharedProps {
    /**
     * Id of material icon to use.
     *
     * See output of following command for full list:
     *
     *     curl -s https://material.io/tools/icons/static/data.json |
     *          jq '.categories | map( .icons | map (.id)) | flatten | sort | .[]'
     *
     */
    icon: string;

    /**
     * Icon fill color.
     */
    color?: string;
}
function Icon({ className, color, icon, size: fontSize = 16 }: IconProps) {
    return (
        <i
            className={classNames('material-icons', className)}
            style={{ color, fontSize }}
        >
            {icon}
        </i>
    );
}
export default memo(Icon);

interface IntentIconProps extends SharedProps {
    /**
     * The icon's intended intent
     */
    intent: Intent;
}
export const IntentIcon = memo(({ intent, ...props }: IntentIconProps) => {
    const icon: Record<Intent, string> = {
        danger: 'error',
        primary: 'info',
        secondary: 'info',
        success: 'check_circle',
        warning: 'warning',
    };
    const color: Record<Intent, string> = {
        danger: '#d32f2f',
        primary: '#01579b',
        secondary: '#00b092',
        success: '#0f9960',
        warning: '#ff9800',
    };
    return <Icon {...props} color={color[intent]} icon={icon[intent]} />;
});
IntentIcon.displayName = 'IntentIcon';
